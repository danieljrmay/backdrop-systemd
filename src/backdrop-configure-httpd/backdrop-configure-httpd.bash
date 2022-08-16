#!/usr/bin/bash
#
# backdrop-configure-httpd
#
# Author: Daniel J. R. May
#
# This script creates an Apache HTTPD configuration for Backdrop CMS
# updates Backdrop's settings.php to match.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-systemd

# Exit codes used by this script.
declare -ir EXIT_OK=0
declare -ir EXIT_UNSET_ENVIRONMENT_VARIABLE=1
declare -ir EXIT_INVALID_ENVIRONMENT_VARIABLE_VALUE=2
declare -ir EXIT_FAILED_TO_CREATE_HTTPD_CONF_FILE=3
declare -ir EXIT_FAILED_TO_MODIFY_SETTINGS_FILE=4
declare -ir EXIT_SETTINGS_FILE_DOES_NOT_EXIST=5

# Systemd log identifier used by this script, so that log messages
# recorded by this script can then be isolated from the mass with:
#
# > journalctl SYSLOG_IDENTIFIER=backdrop-configure-httpd
declare -r identifier='backdrop-configure-httpd'

# Check environment variables required by this script are set.
if ! test -v CREATE_HTTPD_CONF; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The CREATE_HTTPD_CONF environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v HTTPD_CONF_PATH; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The HTTPD_CONF_PATH environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v HTTPD_CONF_TYPE; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The HTTPD_CONF_TYPE environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v DOCUMENT_ROOT; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The DOCUMENT_ROOT environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v PORT; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The PORT environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v MODIFY_SETTINGS_FILE; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The MODIFY_SETTINGS_FILE environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v SETTINGS_FILE_PATH; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The SETTINGS_FILE_PATH environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
else
	systemd-cat \
		--identifier=$identifier \
		echo "All environment variables are set."
fi

# Create the appropriate Apache HTTPD configuration file as a variable.
case "$HTTPD_CONF_TYPE" in
'container')
	httpd_conf_contents=$(
		cat <<EOF
# Apache HTTPD configuration created by backdrop-configure-httpd. This
# configuration is suitable for a container installation of backdrop.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-systemd

DocumentRoot "$DOCUMENT_ROOT"

<Directory "$DOCUMENT_ROOT">
    Require all granted
    AllowOverride All
</Directory>

# Listen on the container hosts mapped port (as well as port 80) so
# that backdrop is able to access itself via HTTP. This is required
# for things like the Testing module to work.
Listen $PORT
EOF
	)
	;;

*)
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Invalid of HTTPD_CONF_TYPE=$HTTPD_CONF_TYPE."
	exit $EXIT_INVALID_ENVIRONMENT_VARIABLE_VALUE
	;;
esac

# Create the Apache HTTPD conf file if required.
if [ "$CREATE_HTTPD_CONF" = false ]; then
	systemd-cat \
		--identifier=$identifier \
		--priority=notice \
		echo "Skipping creation of Apache HTTPD conf file as CREATE_HTTPD_CONF=$CREATE_HTTPD_CONF."
elif test -f "$HTTPD_CONF_PATH"; then
	systemd-cat \
		--identifier=$identifier \
		echo "Skipping creation of Apache HTTPD conf file as $HTTPD_CONF_PATH already exists."
elif echo "$httpd_conf_contents" >"$HTTPD_CONF_PATH"; then
	systemd-cat \
		--identifier=$identifier \
		echo "Created $HTTPD_CONF_PATH successfully."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to create $HTTPD_CONF_PATH, could not write the file."
	exit $EXIT_FAILED_TO_CREATE_HTTPD_CONF_FILE
fi

# Create the additionl to settings.php as a variable.
settings_appendix=$(
	cat <<EOF

/**
 * Added by the backdrop-configure-httpd systemd service.
 */ 
\$settings['trusted_host_patterns'] = array(
    '^localhost:$PORT\$', 
    '^localhost\$',
);
\$database_charset = 'utf8mb4';
EOF
)

# Modify the settings.php file.
if [ "$MODIFY_SETTINGS_FILE" = false ]; then
	systemd-cat \
		--identifier=$identifier \
		--priority=notice \
		echo "Skipping modification of backdrop settings.php as MODIFY_SETTINGS_FILE=$MODIFY_SETTINGS_FILE."
elif [ ! -f "$SETTINGS_FILE_PATH" ]; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Settings file $SETTINGS_FILE_PATH does not exist."
	exit $EXIT_SETTINGS_FILE_DOES_NOT_EXIST
elif echo "$settings_appendix" >>"$SETTINGS_FILE_PATH"; then
	systemd-cat \
		--identifier=$identifier \
		echo "Modified $SETTINGS_FILE_PATH."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to modify $SETTINGS_FILE_PATH."
	exit $EXIT_FAILED_TO_MODIFY_SETTINGS_FILE
fi

exit $EXIT_OK
