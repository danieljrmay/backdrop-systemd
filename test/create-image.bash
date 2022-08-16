#!/usr/bin/bash
#
# create-image
#
# Author: Daniel J. R. May
#
# This script creates a container image for testing the
# backdrop-systemd codebase.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-systemd

# Exit immediately if any command fails.
set -e

# Set the default environment file path. This syntax allows this
# default value to be overridden by an environment variable set before
# this script executes.
: "${ENVIRONMENT_FILE:=backdrop-systemd.env}"

# Echo the environment file used by this script.
echo -e "Variables used by $(basename "$0"):\n"
echo "ENVIRONMENT_FILE=$ENVIRONMENT_FILE"

# Source the environment file.
# shellcheck source=backdrop-systemd.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "BASE_IMAGE=$BASE_IMAGE"
echo "IMAGE_NAME=$IMAGE_NAME"
echo "WORKING_CONTAINER=$WORKING_CONTAINER"
echo

# Echo the commands as this script executes and exit immediately if
# any command fails.
set -ex

# Get the latest fedora image, which serves as a base for our image.
buildah pull "$BASE_IMAGE"

# Create a new container based on the latest version of fedora which
# we will then customise.
buildah from --name "$WORKING_CONTAINER" "$BASE_IMAGE"

# Update the container and install all the packages we need.
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes update
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes install dnf-plugins-core
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes copr enable danieljrmay/backdrop
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes install backdrop mariadb-server
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes clean all

# backdrop-configure-mariadb
buildah copy "$WORKING_CONTAINER" \
	../src/backdrop-configure-mariadb/backdrop-configure-mariadb.service \
	/etc/systemd/system/backdrop-configure-mariadb.service
buildah copy "$WORKING_CONTAINER" \
	../src/backdrop-configure-mariadb/backdrop-configure-mariadb.bash \
	/usr/local/bin/backdrop-configure-mariadb
buildah run "$WORKING_CONTAINER" -- chmod a+x /usr/local/bin/backdrop-configure-mariadb
buildah run "$WORKING_CONTAINER" -- systemctl enable backdrop-configure-mariadb.service

# backdrop-configure-httpd
buildah copy "$WORKING_CONTAINER" \
	../src/backdrop-configure-httpd/backdrop-configure-httpd.service \
	/etc/systemd/system/backdrop-configure-httpd.service
buildah copy "$WORKING_CONTAINER" \
	../src/backdrop-configure-httpd/backdrop-configure-httpd.bash \
	/usr/local/bin/backdrop-configure-httpd
buildah run "$WORKING_CONTAINER" -- chmod a+x /usr/local/bin/backdrop-configure-httpd
buildah run "$WORKING_CONTAINER" -- systemctl enable backdrop-configure-httpd.service

# backdrop-install
buildah copy "$WORKING_CONTAINER" \
	../src/backdrop-install/backdrop-install.service \
	/etc/systemd/system/backdrop-install.service
buildah copy "$WORKING_CONTAINER" \
	../src/backdrop-install/backdrop-install.bash \
	/usr/local/bin/backdrop-install
buildah run "$WORKING_CONTAINER" -- chmod a+x /usr/local/bin/backdrop-install
buildah run "$WORKING_CONTAINER" -- systemctl enable backdrop-install.service

# Expose port 80, the default HTTP port.
buildah config --port 80 "$WORKING_CONTAINER"

# Configure systemd init command as the command to get the container started.
buildah config --cmd "/usr/sbin/init" "$WORKING_CONTAINER"

# Save the container as an image.
buildah commit "$WORKING_CONTAINER" "$IMAGE_NAME"

# Delete the working container.
buildah rm "$WORKING_CONTAINER"
