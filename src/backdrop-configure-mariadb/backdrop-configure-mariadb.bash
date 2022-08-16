#!/usr/bin/bash
#
# backdrop-configure-mariadb
#
# Author: Daniel J. R. May
#
# This script configures mariadb for use by Backdrop CMS.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-systemd

# Exit codes used by this script.
declare -ir EXIT_OK=0
declare -ir EXIT_UNSET_ENVIRONMENT_VARIABLE=1
declare -ir EXIT_FAILED_TO_SECURE_MARIADB=2
declare -ir EXIT_FAILED_TO_CREATE_BACKDROP_DATABASE=3

# Systemd log identifier used by this script, so that log messages
# recorded by this script can then be isolated from the mass with:
#
# > journalctl SYSLOG_IDENTIFIER=backdrop-configure-mariadb
declare -r identifier='backdrop-configure-mariadb'

# Check environment variables required by this script are set.
if ! test -v SECURE_MARIADB; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The SECURE_MARIADB environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v MARIADB_ROOT_AT_LOCALHOST_PASSWORD; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The MARIADB_ROOT_AT_LOCALHOST_PASSWORD environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v MARIADB_MYSQL_AT_LOCALHOST_PASSWORD; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The MARIADB_MYSQL_AT_LOCALHOST_PASSWORD environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v CREATE_BACKDROP_DATABASE; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The CREATE_BACKDROP_DATABASE environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_DATABASE_NAME; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_DATABASE_NAME environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_DATABASE_USER; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_DATABASE_USER environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_DATABASE_PASSWORD; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_DATABASE_PASSWORD environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
else
	systemd-cat \
		--identifier=$identifier \
		echo "All environment variables are set."
fi

# Secure the mariadb installation by running commands similar to the
# mariadb-secure-installation script. However this SQL also changes
# the password of the default 'mysql'@'localhost' account which is
# blank by default.
secure_sql=$(
	cat <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_AT_LOCALHOST_PASSWORD}';
ALTER USER 'mysql'@'localhost' IDENTIFIED BY '${MARIADB_MYSQL_AT_LOCALHOST_PASSWORD}';
DELETE FROM mysql.global_priv WHERE User='';
DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
)

if [ "$SECURE_MARIADB" = false ]; then
	systemd-cat \
		--identifier=$identifier \
		--priority=notice \
		echo "Skipping securing mariadb database as SECURE_MARIADB=$SECURE_MARIADB."
elif ! mariadb --user=root --execute='/* root@localhost is unsecured */' &>/dev/null; then
	systemd-cat \
		--identifier=$identifier \
		echo "Skipping securing mariadb database as root@localhost already seems to be secured."
elif mariadb --user=root --execute="$secure_sql"; then
	systemd-cat \
		--identifier=$identifier \
		echo "Secured the mariadb database installation."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to secure mariadb database installation."
	exit $EXIT_FAILED_TO_SECURE_MARIADB
fi

# Create the backdrop database if it does not already exist and create
# and configure the backdrop database user.
backdrop_sql=$(
	cat <<EOF
CREATE DATABASE ${BACKDROP_DATABASE_NAME};
GRANT ALL ON ${BACKDROP_DATABASE_NAME}.* TO '${BACKDROP_DATABASE_USER}'@'localhost' IDENTIFIED BY '${BACKDROP_DATABASE_PASSWORD}';
FLUSH PRIVILEGES;
EOF
)

if [ "$CREATE_BACKDROP_DATABASE" = false ]; then
	systemd-cat \
		--identifier=$identifier \
		--priority=notice \
		echo "Skipping creation of backdrop database as CREATE_BACKDROP_DATABASE=$CREATE_BACKDROP_DATABASE."
elif mariadb --user=root --host=localhost --password="$MARIADB_ROOT_AT_LOCALHOST_PASSWORD" --execute="QUIT" "$BACKDROP_DATABASE_NAME" &>/dev/null; then
	systemd-cat \
		--identifier=$identifier \
		echo "Skipping creation of backdrop database as a database of the same name already exists."
elif mariadb --user=root --host=localhost --password="$MARIADB_ROOT_AT_LOCALHOST_PASSWORD" --execute="$backdrop_sql"; then
	systemd-cat \
		--identifier=$identifier \
		echo "Created & configured the backdrop database and user."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to create the backdrop database and user."
	exit $EXIT_FAILED_TO_CREATE_BACKDROP_DATABASE
fi

exit $EXIT_OK
