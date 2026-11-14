#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${SCRIPT_DIR}/extra-repos"
KEY_DIR="${SCRIPT_DIR}/repo-gpg-keys"

export_repos() {
    echo "=== Exporting third-party RPM repositories ==="

    mkdir -p "$REPO_DIR" "$KEY_DIR"
    rm -f "$REPO_DIR/"*.repo

    for repo in /etc/yum.repos.d/*.repo; do
        [[ -f "$repo" ]] || continue

        owner=$(rpm -qf --qf '%{NAME}\n' "$repo" 2>/dev/null || true)

        case "$owner" in
            fedora-repos*|fedora-workstation-repositories)
                continue
                ;;
        esac

        cp "$repo" "$REPO_DIR/"
        echo "Exported: $(basename "$repo")"
    done

    # Preserve public RPM signing keys used by local repositories.
    cp -a /etc/pki/rpm-gpg/. "$KEY_DIR/"

    echo "Repository export complete."
}

apply_setup() {
    TARGET_USER="${SUDO_USER:-$(id -un)}"

    if [[ "$TARGET_USER" == "root" ]]; then
        echo "ERROR: Run as your normal user, not root."
        exit 1
    fi

    echo "=== Configuring groups for $TARGET_USER ==="

    for group in docker libvirt kvm; do
        if ! getent group "$group" >/dev/null; then
            sudo groupadd --system "$group"
        fi

        sudo usermod -aG "$group" "$TARGET_USER"
        echo "Added $TARGET_USER to $group"
    done

    echo "=== Restoring RPM signing keys ==="

    if [[ -d "$KEY_DIR" ]]; then
        for key in "$KEY_DIR"/*; do
            [[ -f "$key" ]] || continue
            destination="/etc/pki/rpm-gpg/$(basename "$key")"

            if [[ ! -e "$destination" ]]; then
                sudo install -m 0644 "$key" "$destination"
            fi
        done
    fi

    echo "=== Restoring third-party RPM repositories ==="

    if [[ ! -d "$REPO_DIR" ]]; then
        echo "ERROR: Missing extra-repos directory."
        exit 1
    fi

    for repo in "$REPO_DIR"/*.repo; do
        [[ -f "$repo" ]] || continue

        destination="/etc/yum.repos.d/$(basename "$repo")"

        if [[ -f "$destination" ]] && ! cmp -s "$repo" "$destination"; then
            sudo cp -a "$destination" "${destination}.bak"
        fi

        sudo install -m 0644 "$repo" "$destination"
        echo "Restored: $(basename "$repo")"
    done

    echo "=== Refreshing DNF repositories ==="
    sudo dnf makecache --refresh

    echo "=== Enabled repositories ==="
    dnf repolist --enabled

    echo "=== Setup complete ==="
    echo "Log out and back in to activate new group memberships."
}

case "${1:-}" in
    export)
        export_repos
        ;;
    apply)
        apply_setup
        ;;
    *)
        echo "Usage: $0 {export|apply}"
        exit 1
        ;;
esac

