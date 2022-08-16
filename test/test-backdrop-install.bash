#!/usr/bin/bash
#
# test-backdrop-configure-httpd
#
# Author: Daniel J. R. May
#
# This script creates a container suitable for testing the
# backdrop-configure-httpd systemd service.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-systemd

# Exit immediately if any command fails.
set -e

# Variables
IMAGE=backdrop-systemd
CONTAINER=backdrop-install
CONTAINER_HOSTNAME=backdrop-install-test
MARIADB_SECRET_NAME=backdrop-configure-mariadb
HTTPD_SECRET_NAME=backdrop-configure-httpd
INSTALL_SECRET_NAME=backdrop-install
PORT=39080

# Create the secret variables.
mariadb_secret=$(
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
httpd_secret=$(
	cat <<EOF
CREATE_HTTPD_CONF=true
HTTPD_CONF_PATH='/etc/httpd/conf.d/backdrop.conf'
HTTPD_CONF_TYPE='container'
DOCUMENT_ROOT='/usr/share/backdrop'
PORT=$PORT
MODIFY_SETTINGS_FILE=true
SETTINGS_FILE_PATH='/etc/backdrop/settings.php'
EOF
)
install_secret=$(
	cat <<EOF
SKIP_BACKDROP_INSTALLATION=false
BACKDROP_DATABASE_NAME='backdrop'
BACKDROP_DATABASE_USER='backdrop_database_user'
BACKDROP_DATABASE_PASSWORD='backdrop_database_password'
BACKDROP_DATABASE_HOST='localhost'
BACKDROP_DATABASE_PREFIX=''
BACKDROP_ACCOUNT_NAME='admin'
BACKDROP_ACCOUNT_PASSWORD='admin_pwd'
BACKDROP_ACCOUNT_MAIL='admin@example.com'
BACKDROP_CLEAN_URL=1
BACKDROP_LANGCODE='en'
BACKDROP_SITE_MAIL='admin@example.com'
BACKDROP_SITE_NAME='backdrop-install test'
EOF
)

# Echo the commands as this script executes.
set -x

# Check base image exists.
podman image exists "$IMAGE"

# Remove any pre-existing secrets, but do not error if no such secret
# exists.
podman secret rm "$MARIADB_SECRET_NAME" "$HTTPD_SECRET_NAME" "$INSTALL_SECRET_NAME" || true

# Temporarily turn off command echoing (so we do not reveal any
# secrets), create the secrets and then turn command echoing back on
# again.
set +x
echo "Creating the $MARIADB_SECRET_NAME secret…"
echo "$mariadb_secret" | podman secret create "$MARIADB_SECRET_NAME" -
echo "Creating the $HTTPD_SECRET_NAME secret…"
echo "$httpd_secret" | podman secret create "$HTTPD_SECRET_NAME" -
echo "Creating the $INSTALL_SECRET_NAME secret…"
echo "$install_secret" | podman secret create "$INSTALL_SECRET_NAME" -
set -x

# Create and start the container.
podman run \
	--name "$CONTAINER" \
	--secret source="$MARIADB_SECRET_NAME",type=mount,mode=400,target="$MARIADB_SECRET_NAME" \
	--secret source="$HTTPD_SECRET_NAME",type=mount,mode=400,target="$HTTPD_SECRET_NAME" \
	--secret source="$INSTALL_SECRET_NAME",type=mount,mode=400,target="$INSTALL_SECRET_NAME" \
	--hostname "$CONTAINER_HOSTNAME" \
	--publish "$PORT:80" \
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
