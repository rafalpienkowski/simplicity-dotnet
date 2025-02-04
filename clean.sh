#!/bin/zsh

# Configuration
CONTAINER_NAME="postgres_container"
VOLUME_NAME="postgres_data"

# Stop and remove the container if it exists
if podman ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    podman stop $CONTAINER_NAME
    podman rm $CONTAINER_NAME
    echo "Container $CONTAINER_NAME has been removed."
else
    echo "Container $CONTAINER_NAME does not exist."
fi

# Remove the volume if it exists
if podman volume exists $VOLUME_NAME; then
    podman volume rm $VOLUME_NAME
    echo "Volume $VOLUME_NAME has been removed."
else
    echo "Volume $VOLUME_NAME does not exist."
fi
