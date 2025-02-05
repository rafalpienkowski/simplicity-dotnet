#!/bin/bash

# Configuration
CONTAINER_NAME="postgres_container"
IMAGE="docker.io/postgres:latest"
PORT=5432
DB_USER="postgres"
DB_PASSWORD="mypassword"
DB_NAME="simplicity"
VOLUME_NAME="postgres_data"
SEED_FILE="$(dirname "$0")/seed.sql"

# Run the container
podman run -d \
    --name $CONTAINER_NAME \
    -e POSTGRES_USER=$DB_USER \
    -e POSTGRES_PASSWORD=$DB_PASSWORD \
    -e POSTGRES_DB=$DB_NAME \
    -p $PORT:5432 \
    -v $VOLUME_NAME:/var/lib/postgresql/data \
    --restart unless-stopped \
    $IMAGE

# Wait for PostgreSQL to be ready
until podman exec $CONTAINER_NAME pg_isready -U $DB_USER; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done

# Run the seed script
if [[ -f "$SEED_FILE" ]]; then
    podman cp "$SEED_FILE" $CONTAINER_NAME:/seed.sql
    podman exec -u $DB_USER $CONTAINER_NAME psql -d $DB_NAME -f /seed.sql
    echo "Seed script executed successfully."
else
    echo "Seed file not found: $SEED_FILE"
fi

echo "PostgreSQL is running in Podman container: $CONTAINER_NAME"

