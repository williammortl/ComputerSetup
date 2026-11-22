
#!/usr/bin/env bash
#
# Fedora System Health Check
# Standard: ./healthCheck.sh
# Deep:     ./healthCheck.sh --deep
#
# Read-only diagnostics. No repairs or configuration changes.
#

set -u
export LC_ALL=C

DEEP=false
if [[ "${1:-}" == "--deep" ]]; then
    DEEP=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--deep]"
    exit 2
fi

DATE=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT="healthReport_${DATE}.txt"

# Capture pressure BEFORE diagnostic activity.
BASE_IO=$(cat /proc/pressure/io 2>/dev/null)
BASE_MEM=$(cat /proc/pressure/memory 2>/dev/null)
BASE_CPU=$(cat /proc/pressure/cpu 2>/dev/null)

# Obtain sudo authorization once.
if ! sudo -v; then
    echo "Unable to obtain sudo authorization."
    exit 1
fi

# Temporary journal cache.
TMPDIR_HEALTH=$(mktemp -d) || exit 1
trap 'rm -rf "$TMPDIR_HEALTH"' EXIT

# Keep the journal snapshot consistent across checks.
timeout 15s sudo journalctl -k -b --no-pager \
    -o short-iso > "$TMPDIR_HEALTH/kernel.log" 2>/dev/null
KERNEL_RC=$?

timeout 15s sudo journalctl -b -p err..alert \
    --no-pager -o short-iso \
    > "$TMPDIR_HEALTH/errors.log" 2>/dev/null
ERRORS_RC=$?

section() {
    printf '\n'
    printf '%s\n' \
        "============================================================"
    printf '%s\n' "$1"
    printf '%s\n' \
        "============================================================"
}

run_timeout() {
    local seconds="$1"
    shift
    timeout "${seconds}s" "$@"
}

run_optional() {
    if command -v "$1" >/dev/null 2>&1; then
        "$@"
    else
        echo "Unavailable: $1"
    fi
}

# Identify the first NVMe disk.
NVME_DISK=$(
    lsblk -dn -o NAME,TYPE 2>/dev/null |
        awk '$2=="disk" && $1 ~ /^nvme[0-9]+n[0-9]+$/ {
            print "/dev/" $1
            exit
        }'
)

# Convert /dev/nvme0n1 to /dev/nvme0.
NVME_CTRL=""
if [[ -n "$NVME_DISK" ]]; then
    NVME_CTRL="${NVME_DISK%n*}"
fi

{
section "SYSTEM HEALTH REPORT"

echo "Generated: $(date)"
echo "Hostname:  $(hostname)"
echo "Mode:      $($DEEP && echo DEEP || echo STANDARD)"
echo "Report:    $REPORT"

section "SYSTEM AND KERNEL"

uname -a
uptime

echo
echo "Operating system:"
cat /etc/os-release

section "BASELINE SYSTEM PRESSURE"

echo "Captured before diagnostics."

echo
echo "I/O pressure:"
echo "$BASE_IO"

echo
echo "Memory pressure:"
echo "$BASE_MEM"

echo
echo "CPU pressure:"
echo "$BASE_CPU"

echo
echo "Interpretation:"
echo "PSI measures time tasks were stalled."
echo "Nonzero historical totals alone are not errors."
echo "The 10/60/300-second averages are rolling windows."

section "MEMORY"

free -h

echo
echo "Swap:"
swapon --show

section "FILESYSTEM USAGE"

df -hT

echo
echo "Root mount:"
findmnt -no SOURCE,FSTYPE,OPTIONS /

echo
echo "Block devices:"
lsblk -o NAME,MODEL,SIZE,TYPE,FSTYPE,MOUNTPOINTS

section "NVME SMART HEALTH"

if [[ -n "$NVME_CTRL" ]] &&
   command -v nvme >/dev/null 2>&1; then

    echo "Controller: $NVME_CTRL"

    echo
    echo "SMART:"
    run_timeout 10 sudo nvme smart-log "$NVME_CTRL"

    echo
    echo "Identity:"
    run_timeout 10 sudo nvme id-ctrl "$NVME_CTRL" |
        grep -Ei '^(sn|mn|fr)[[:space:]]*:'

    echo
    echo "Error log:"
    run_timeout 10 sudo nvme error-log "$NVME_CTRL" -e 4

else
    echo "NVMe controller or nvme-cli unavailable."
fi

section "BATTERY"

if command -v upower >/dev/null 2>&1; then
    BATTERY=$(
        upower -e 2>/dev/null |
            grep '/battery_' |
            head -n 1
    )

    if [[ -n "$BATTERY" ]]; then
        upower -i "$BATTERY"
    else
        echo "No battery detected."
    fi
else
    echo "UPower unavailable."
fi

section "TEMPERATURES"

run_optional sensors

section "SYSTEMD HEALTH"

echo "Failed system units:"
systemctl --failed --no-pager

echo
echo "Failed user units:"
systemctl --user --failed --no-pager 2>&1 || true

section "FIRMWARE AND PLATFORM"

echo "BIOS vendor:"
sudo dmidecode -s bios-vendor

echo
echo "BIOS version:"
sudo dmidecode -s bios-version

echo
echo "BIOS date:"
sudo dmidecode -s bios-release-date

echo
echo "System model:"
sudo dmidecode -s system-product-name

echo
echo "CPU microcode:"
grep -m1 -i microcode /proc/cpuinfo || true

echo
echo "TPM:"
ls -l /sys/class/tpm/ 2>/dev/null || true

echo
echo "TPM PCR0:"
if command -v tpm2_pcrread >/dev/null 2>&1; then
    run_timeout 5 sudo tpm2_pcrread sha256:0
else
    echo "tpm2-tools unavailable."
fi

section "FIRMWARE PACKAGES"

rpm -q \
    linux-firmware \
    fwupd \
    microcode_ctl \
    shim-x64 \
    grub2-efi-x64 2>&1

section "FIRMWARE SECURITY"

if command -v fwupdmgr >/dev/null 2>&1; then
    echo "Firmware security assessment:"
    run_timeout 15 fwupdmgr security

    echo
    echo "Firmware update status:"
    echo "Not queried during routine health checks."
    echo "Use 'fwupdmgr get-updates' separately when needed."
else
    echo "fwupdmgr unavailable."
fi

section "SECURITY CONTROLS"

echo "SELinux:"
if command -v getenforce >/dev/null 2>&1; then
    getenforce
else
    echo "SELinux utilities unavailable."
fi

echo
echo "Secure Boot:"
run_optional mokutil --sb-state

echo
echo "Kernel lockdown:"
cat /sys/kernel/security/lockdown 2>/dev/null ||
    echo "Unavailable"

echo
echo "Intel SPI protection:"
for f in /sys/bus/pci/devices/0000:00:1f.5/intel_spi_*; do
    [[ -e "$f" ]] || continue
    printf "%s: " "${f##*/}"
    sudo cat "$f"
done

section "KERNEL WARNINGS"

if [[ "$KERNEL_RC" -eq 0 ]]; then
    grep -Ei \
        'firmware bug|hardware error|machine check|BUG:|kernel panic|general protection fault|call trace|Oops:' \
        "$TMPDIR_HEALTH/kernel.log" |
        tail -n 80 || true
else
    echo "Kernel journal snapshot unavailable."
fi

echo
echo "Note: Firmware warnings are not automatically"
echo "evidence of failing hardware."

section "SYSTEM ERRORS"

if [[ "$ERRORS_RC" -eq 0 ]]; then
    tail -n 100 "$TMPDIR_HEALTH/errors.log"
else
    echo "System error journal unavailable."
fi

section "HARDWARE ERROR MONITORING"

if [[ "$KERNEL_RC" -eq 0 ]]; then
    grep -Ei \
        'mce:.*(error|corrected|uncorrected)|machine check exception|hardware error|EDAC.*(CE|UE|error)|AER:.*error' \
        "$TMPDIR_HEALTH/kernel.log" |
        tail -n 50 || true
fi

section "STORAGE ERROR MONITORING"

if [[ "$KERNEL_RC" -eq 0 ]]; then
    grep -Ei \
        'I/O error|blk_update_request|nvme.*(timeout|reset|abort)|Buffer I/O error|critical medium error' \
        "$TMPDIR_HEALTH/kernel.log" |
        tail -n 50 || true
fi

section "GPU DRIVER HEALTH"

lspci -k -s 00:02.0

echo
echo "GPU errors:"
if [[ "$KERNEL_RC" -eq 0 ]]; then
    grep -Ei \
        '(i915|xe|drm).*(GPU HANG|hangcheck|resetting chip|atomic update failure|fifo underrun|GPU fault)' \
        "$TMPDIR_HEALTH/kernel.log" |
        tail -n 50 || true
fi

section "THERMAL THROTTLING"

if [[ "$KERNEL_RC" -eq 0 ]]; then
    grep -Ei \
        'thermal.*thrott|temperature above threshold|critical temperature' \
        "$TMPDIR_HEALTH/kernel.log" |
        tail -n 30 || true
fi

section "BTRFS HEALTH"

ROOT_FS=$(findmnt -n -o FSTYPE /)

if [[ "$ROOT_FS" == "btrfs" ]]; then

    echo "Filesystem usage:"
    sudo btrfs filesystem usage -T /

    echo
    echo "Device error statistics:"
    sudo btrfs device stats /

    echo
    echo "Device error check:"
    if sudo btrfs device stats -c / >/dev/null; then
        echo "PASS: All counters zero."
    else
        echo "WARNING: Nonzero device error counters."
    fi

    echo
    echo "Scrub history:"
    sudo btrfs scrub status -d /

    echo
    echo "Scrub timer:"
    systemctl is-enabled btrfs-scrub.timer 2>/dev/null || true
    systemctl is-active btrfs-scrub.timer 2>/dev/null || true

    echo
    echo "Next scrub:"
    systemctl list-timers --all \
        btrfs-scrub.timer --no-pager

    echo
    echo "Scrub configuration:"
    if [[ -f /etc/sysconfig/btrfsmaintenance ]]; then
        grep -E \
            '^BTRFS_(SCRUB|BALANCE|DEFRAG|TRIM)_(PERIOD|MOUNTPOINTS)=' \
            /etc/sysconfig/btrfsmaintenance
    else
        echo "Maintenance configuration unavailable."
    fi

    echo
    echo "Maintenance timer enablement:"
    for timer in \
        btrfs-balance.timer \
        btrfs-defrag.timer \
        btrfs-trim.timer; do

        printf "%s: " "$timer"
        systemctl is-enabled "$timer" 2>/dev/null ||
            true
    done

    echo
    echo "Btrfs kernel errors:"
    if [[ "$KERNEL_RC" -eq 0 ]]; then
        grep -Ei \
            'BTRFS.*(error|corrupt|failed|warning)' \
            "$TMPDIR_HEALTH/kernel.log" ||
            echo "No matching Btrfs errors."
    fi

else
    echo "Root filesystem is $ROOT_FS."
    echo "Btrfs-specific diagnostics skipped."
fi

section "VIRTUALIZATION AND CONTAINERS"

echo "KVM:"
if [[ -e /dev/kvm ]]; then
    ls -l /dev/kvm
else
    echo "Not present."
fi

echo
echo "libvirt:"
systemctl is-active virtqemud.socket 2>/dev/null || true
systemctl is-active libvirtd.service 2>/dev/null || true

echo
echo "Docker:"
systemctl is-active docker.service 2>/dev/null || true

if command -v docker >/dev/null 2>&1; then
    run_timeout 5 docker info --format \
        'Server: {{.ServerVersion}}, Containers: {{.Containers}}' \
        2>/dev/null || true
fi

echo
echo "Firewall:"
if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --state 2>/dev/null || true
    firewall-cmd --get-policies 2>/dev/null || true
fi

section "NETWORK INTERFACES"

ip -br link

echo
echo "Interface error counters:"
for iface in /sys/class/net/*; do
    name="${iface##*/}"
    [[ "$name" == "lo" ]] && continue

    echo "Interface: $name"

    for counter in \
        rx_errors tx_errors rx_dropped tx_dropped; do

        file="$iface/statistics/$counter"

        if [[ -r "$file" ]]; then
            printf "  %s: %s\n" \
                "$counter" "$(cat "$file")"
        fi
    done
done

section "SYSTEM CLOCK"

timedatectl status

section "PACKAGE HEALTH"

echo "Fedora package manager: DNF5"

if $DEEP; then

    echo
    echo "DNF consistency check:"
    echo "Low-priority, 25-second limit."

    timeout 25s \
        nice -n 15 ionice -c 3 \
        sudo -n dnf check

    rc=$?

    case "$rc" in
        0)
            echo "PASS: DNF consistency check."
            ;;
        124)
            echo "INCOMPLETE: DNF check timed out."
            ;;
        *)
            echo "CHECK: DNF exited with status $rc."
            ;;
    esac

    echo
    echo "Extra packages:"
    timeout 15s \
        nice -n 15 ionice -c 3 \
        sudo -n dnf list --extras ||
        echo "Extra-package check incomplete."

else
    echo "Extended package checks skipped."
    echo "Use --deep to include DNF consistency."
fi

echo
echo "Full RPM installed-file verification is intentionally"
echo "excluded because it can generate substantial disk I/O."

section "POST-DIAGNOSTIC PRESSURE"

echo "These values may include pressure caused by this script."

echo
echo "I/O pressure:"
cat /proc/pressure/io

echo
echo "Memory pressure:"
cat /proc/pressure/memory

echo
echo "CPU pressure:"
cat /proc/pressure/cpu

echo
echo "Disk statistics:"
if [[ -n "$NVME_DISK" ]]; then
    grep -F " ${NVME_DISK##*/} " /proc/diskstats ||
        true
fi

echo
echo "Important:"
echo "PSI totals accumulate since boot."
echo "Do not treat accumulated totals as current errors."
echo "Use pre-diagnostic baseline for health assessment."

section "HEALTH REPORT COMPLETE"

echo "Completed: $(date)"
echo "Mode: $($DEEP && echo DEEP || echo STANDARD)"
echo "Report: $REPORT"

} > "$REPORT" 2>&1

echo "Health report written to:"
echo "$REPORT"

