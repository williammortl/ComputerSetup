#!/usr/bin/env bash

set -euo pipefail
umask 077

# Restrict direct host filesystem access for ten Flatpak applications.
# Every app gets Downloads. Selected apps receive an additional working folder.
# App-private ~/.var/app/<app-id> data is unaffected.
# Usage: ./lockdownFlatpaks.sh [--audit|--apply|--restore BACKUP_DIR]

APPS=(
  io.github.ungoogled_software.ungoogled_chromium
  org.mozilla.firefox
  org.mozilla.thunderbird
  us.zoom.Zoom
  com.slack.Slack
  com.discordapp.Discord
  org.octave.Octave
  com.vscodium.codium
  org.libreoffice.LibreOffice
  io.github.dosbox-staging
)

OVERRIDE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/overrides"
BACKUP_ROOT="$HOME/flatpak-lockdown-backups"
DOS_DIR="$HOME/VMs/DOS"

usage() {
  printf 'Usage: %s [--audit|--apply|--restore BACKUP_DIR]\n' "$0"
}

installed() { flatpak info "$1" >/dev/null 2>&1; }

# Add only specific integrations that can matter for normal app operation.
# These are narrower than a home/host mount and do not grant broad document access.
# Do NOT preserve ~/.gnupg, ~/.local/share/applications, or ~/Documents/Zoom.
make_grants() {
  local app="$1"
  GRANTS=(--nofilesystem=host:reset --filesystem=xdg-download)
  case "$app" in
    io.github.ungoogled_software.ungoogled_chromium)
      GRANTS+=(--filesystem=xdg-run/pipewire-0 --filesystem=xdg-run/dconf)
      ;;
    org.mozilla.firefox)
      GRANTS+=(--filesystem=xdg-run/speech-dispatcher:ro)
      ;;
    org.mozilla.thunderbird)
      GRANTS+=(--filesystem=xdg-run/speech-dispatcher:ro)
      ;;
    com.discordapp.Discord)
      GRANTS+=(--filesystem=xdg-run/pipewire-0)
      ;;
    org.octave.Octave|com.vscodium.codium)
      GRANTS+=(--filesystem="$HOME/Code")
      ;;
    org.libreoffice.LibreOffice)
      GRANTS+=(--filesystem="$HOME/Documents")
      # Preserve per-user font and GTK theme configuration (read-only).
      GRANTS+=(--filesystem=xdg-config/fontconfig:ro --filesystem=xdg-config/gtk-3.0:ro)
      ;;
    io.github.dosbox-staging)
      GRANTS+=(--filesystem="$DOS_DIR")
      # On Cosmos, DOSBox's host config is ~/.config/dosbox.
      GRANTS+=(--filesystem=xdg-config/dosbox:create --filesystem=xdg-run/pipewire-0:ro)
      ;;
  esac
  # Prevent VSCodium extensions from using flatpak-spawn --host.
  # Filesystem restrictions are ineffective if the editor can spawn host commands.
  if [[ "$app" == com.vscodium.codium ]]; then
    GRANTS+=(--no-talk-name=org.freedesktop.Flatpak)
  fi
}

show() {
  printf 'Policy: all ten apps -> Downloads; Octave/VSCodium -> Code; LibreOffice -> Documents; DOSBox -> VMs/DOS.\n'
  printf 'Additional narrowly scoped runtime/config permissions are noted in the script.\n'
  for app in "${APPS[@]}"; do
    printf '\n===== %s =====\n' "$app"
    if ! installed "$app"; then
      printf 'Not installed.\n'
      continue
    fi
    printf 'Packaged filesystem permissions (before overrides):\n'
    flatpak info --show-permissions "$app" | grep '^filesystems=' || true
    printf 'User overrides:\n'
    flatpak override --user --show "$app" || true
    printf 'System overrides:\n'
    flatpak override --system --show "$app" || true
  done
  printf '\nNOTE: Flatpak file portals may grant access to individually selected files elsewhere.\n'
}

apply() {
  command -v flatpak >/dev/null || { echo 'ERROR: flatpak not found.' >&2; exit 1; }
  local app
  for app in "${APPS[@]}"; do
    installed "$app" || { printf 'ERROR: %s is not installed. No changes made.\n' "$app" >&2; exit 1; }
  done
  for dir in "$HOME/Downloads" "$HOME/Documents" "$HOME/Code" "$DOS_DIR"; do
    [[ -d "$dir" ]] || { printf 'ERROR: required directory missing: %s\n' "$dir" >&2; exit 1; }
  done

  mkdir -p -m 700 "$BACKUP_ROOT"
  local backup
  backup="$(mktemp -d "$BACKUP_ROOT/backup-XXXXXXXX")"
  chmod 700 "$backup"
  printf '%s\n' "${APPS[@]}" > "$backup/apps.txt"
  for app in "${APPS[@]}"; do
    if [[ -f "$OVERRIDE_DIR/$app" ]]; then
      cp -p "$OVERRIDE_DIR/$app" "$backup/$app"
    fi
    flatpak override --user --show "$app" > "$backup/$app.before.txt"
    flatpak info --show-permissions "$app" > "$backup/$app.manifest.txt"
  done
  printf 'Backup saved: %s\n' "$backup"
  echo 'This will replace existing per-app USER overrides for these ten applications.'
  echo 'It does not modify global or system overrides, app profiles, or caches.'
  echo 'Close the ten applications before proceeding.'
  local confirmation
  read -r -p 'Type APPLY to continue: ' confirmation
  if [[ "$confirmation" != APPLY ]]; then
    echo 'Cancelled. No changes made.'
    return 0
  fi

  for app in "${APPS[@]}"; do
    make_grants "$app"
    printf 'Applying policy to %s\n' "$app"
    flatpak override --user --reset "$app"
    flatpak override --user "${GRANTS[@]}" "$app"
  done

  echo
  echo 'Applied. Fully close and restart each affected Flatpak.'
  printf 'To restore previous user overrides: %s --restore %q\n' "$0" "$backup"
  echo 'To inspect: run this script with --audit.'
}

restore() {
  local backup="${1:-}"
  [[ -n "$backup" && -f "$backup/apps.txt" ]] || {
    echo 'ERROR: supply an existing backup directory containing apps.txt.' >&2
    exit 1
  }
  local app
  while IFS= read -r app; do
    [[ -n "$app" ]] || continue
    flatpak override --user --reset "$app"
    if [[ -f "$backup/$app" ]]; then
      mkdir -p "$OVERRIDE_DIR"
      cp -p "$backup/$app" "$OVERRIDE_DIR/$app"
    fi
    printf 'Restored %s\n' "$app"
  done < "$backup/apps.txt"
  echo 'Restart affected applications. System and global overrides were untouched.'
}

case "${1:---audit}" in
  --audit) show ;;
  --apply) apply ;;
  --restore) restore "${2:-}" ;;
  *) usage; exit 2 ;;
esac
