#!/usr/bin/env bash
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="$BASE/flatpak-export"

if [[ $(id -u) -eq 0 ]]; then
    echo "Run as your normal user, not root."
    exit 1
fi

export_flatpaks() {
    echo "=== Exporting Flatpak configuration ==="

    for scope in system user; do
        mkdir -p "$DATA/keys/$scope"

        echo "Exporting $scope applications..."

        flatpak list --app --"$scope" \
            --columns=application,origin,branch \
            > "$DATA/apps-$scope.tsv"

        flatpak remotes --"$scope" --show-disabled \
            --columns=name,url,options \
            > "$DATA/remotes-$scope.tsv"

        if [[ "$scope" == "system" ]]; then
            repo="/var/lib/flatpak/repo"
        else
            repo="$HOME/.local/share/flatpak/repo"
        fi

        # Save public signing keys for configured remotes.
        while IFS=$'\t' read -r name url options; do
            [[ -n "$name" && "$name" != "Name" ]] || continue
            [[ "$name" =~ ^[a-zA-Z0-9._-]+$ ]] || continue

            key="$repo/$name.trustedkeys.gpg"

            if [[ -f "$key" ]]; then
                cp "$key" "$DATA/keys/$scope/"
            fi
        done < "$DATA/remotes-$scope.tsv"
    done

    echo "Export complete: $DATA"
}

apply_flatpaks() {
    echo "=== Restoring Flatpak configuration ==="

    local failures=0

    for scope in system user; do
        echo "Restoring $scope repositories..."

        while IFS=$'\t' read -r name url options; do
            [[ -n "$name" && "$name" != "Name" ]] || continue
            [[ "$name" =~ ^[a-zA-Z0-9._-]+$ ]] || continue
            [[ -n "$url" && "$url" != "URL" ]] || continue

            if [[ "$options" == *no-gpg-verify* ]]; then
                echo "WARNING: $name has GPG verification disabled."
                echo "Review and restore this remote manually."
                ((failures+=1))
                continue
            fi

            cmd=(flatpak remote-add --"$scope" --if-not-exists)

            if [[ "$options" == *disabled* ]]; then
                cmd+=(--disable)
            fi

            key="$DATA/keys/$scope/$name.trustedkeys.gpg"

            if [[ "$name" == "flathub" &&
                  "$url" == *flathub.org* ]]; then
                source="https://dl.flathub.org/repo/flathub.flatpakrepo"
            else
                source="$url"

                if [[ -s "$key" ]]; then
                    cmd+=("--gpg-import=$key")
                fi
            fi

            if ! "${cmd[@]}" "$name" "$source"; then
                echo "FAILED: Repository $name ($scope)"
                ((failures+=1))
            fi
        done < "$DATA/remotes-$scope.tsv"

        echo "Installing $scope applications..."

        while IFS=$'\t' read -r app remote branch; do
            [[ -n "$app" ]] || continue
            [[ "$app" != "Application" &&
               "$app" != "Application ID" ]] || continue
            [[ -n "$remote" && -n "$branch" ]] || continue

            echo "Installing: $app ($branch)"

            if ! flatpak install --"$scope" -y \
                "$remote" "$app//$branch"; then
                echo "FAILED: $app"
                ((failures+=1))
            fi
        done < "$DATA/apps-$scope.tsv"
    done

    echo "=== Flatpak restoration complete ==="
    echo "Failures: $failures"

    [[ "$failures" -eq 0 ]]
}

case "${1:-}" in
    export)
        export_flatpaks
        ;;
    apply)
        apply_flatpaks
        ;;
    *)
        echo "Usage: $0 {export|apply}"
        exit 1
        ;;
esac

