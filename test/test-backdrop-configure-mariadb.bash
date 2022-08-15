#!/usr/bin/bash
#
# create-container
#
# Author: Daniel J. R. May
#
# This script creates a container suitable for backdrop-systemd
# codebase testing.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-systemd

# Exit immediately if any command fails.
set -e

# Variables
IMAGE=backdrop-systemd
CONTAINER=backdrop-configure-mariadb
SECRET_NAME=backdrop-configure-mariadb
CONTAINER_HOSTNAME=backdrop-configure-mariadb

# Create the secret variable.
secret=$(
	cat <<EOF
SECURE_MARIADB=true
MARIADB_ROOT_AT_LOCALHOST_PASSWORD='mariadb_root_at_localhost_password'
MARIADB_MYSQL_AT_LOCALHOST_PASSWORD='mariadb_mysql_at_localhost_password'
CREATE_BACKDROP_DATABASE=true
BACKDROP_DATABASE_NAME='backdrop'
BACKDROP_DATABASE_USER='backdrop_database_user'
BACKDROP_DATABASE_PASSWORD='backdrop_database_password'
EOF
)

# Echo the commands as this script executes.
set -x

# Check base image exists.
podman image exists "$IMAGE"

# Remove any pre-existing secret, but do not error if no such secret
# exists.
podman secret rm "$SECRET_NAME" || true

# Temporarily turn off command echoing (so we do not reveal any
# secrets), create the secret and then turn command echoing back on
# again.
set +x
echo "Creating the $SECRET_NAME secret…"
echo "$secret" | podman secret create "$SECRET_NAME" -
set -x

# Create and start the container.
podman run \
	--name "$CONTAINER" \
	--secret source="$SECRET_NAME",type=mount,mode=400,target="$SECRET_NAME" \
	--hostname "$CONTAINER_HOSTNAME" \
	--detach \
	"$IMAGE"

# Explore the container.
podman exec \
	--interactive \
	--tty \
	"$CONTAINER" \
	/usr/bin/bash

# Stop and remove the container.
podman stop "$CONTAINER"
podman rm "$CONTAINER"
