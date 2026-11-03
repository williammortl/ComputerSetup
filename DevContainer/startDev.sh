#!/usr/bin/bash

set -euo pipefail

CONTAINER_NAME="wmm_dev"
IMAGE="localhost/wmm_dev:latest"
CODE_DIR="$HOME/Code"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_KEY="gitkub_key"
GITHUB_KEY_PATH="$HOME/.ssh/$GITHUB_KEY"

if [[ ! -d "$CODE_DIR" ]]; then
    echo "ERROR: $CODE_DIR does not exist."
    exit 1
fi

if [[ ! -f "$GITHUB_KEY_PATH" || ! -f "$GITHUB_KEY_PATH.pub" ]]; then
    echo "ERROR: GitHub SSH key pair not found with name $GITHUB_KEY"
    exit 1
fi

LATEST_IMAGE_ID=$(podman image inspect "$IMAGE" --format '{{.Id}}')

if podman container exists "$CONTAINER_NAME"; then
    CONTAINER_IMAGE_ID=$(podman inspect "$CONTAINER_NAME" --format '{{.Image}}')
    if [[ "$CONTAINER_IMAGE_ID" != "$LATEST_IMAGE_ID" ]]; then
        echo "ERROR: Development container uses an older image."
        echo "Back up important container data before recreating it."
        exit 1
    fi

	if [[ "$(podman inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" == "true" ]]; then
		echo "Development container is already running."
	else
		echo "Starting existing development container..."
		podman start "$CONTAINER_NAME" >/dev/null
	fi
else
    echo "Creating development container..."
    podman run -d \
        --name "$CONTAINER_NAME" \
        --userns=keep-id \
        --cap-drop=ALL \
        --security-opt=no-new-privileges \
        -v "$CODE_DIR:/Code:rw,Z" \
		-e GIT_SSH_COMMAND="ssh -i /home/dev/.ssh/$GITHUB_KEY -o IdentitiesOnly=yes" \
        -w /Code \
		--init \
		"$IMAGE" \
		sleep infinity >/dev/null
		
	# Copy GitHub keys only when creating the container
	podman cp "$GITHUB_KEY_PATH" \
	    "$CONTAINER_NAME:/home/dev/.ssh/$GITHUB_KEY"

	podman cp "$GITHUB_KEY_PATH.pub" \
	    "$CONTAINER_NAME:/home/dev/.ssh/$GITHUB_KEY.pub"
fi

"$SCRIPT_DIR/enterDev.sh"
