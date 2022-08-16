#!/usr/bin/bash
#
# backdrop-install
#
# Author: Daniel J. R. May
#
# This script installs backdrop using environment variables for
# configuration. This script should be called only once per backdrop
# site instance.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm

# Exit codes used by this script.
declare -ir EXIT_OK=0
declare -ir EXIT_UNSET_ENVIRONMENT_VARIABLE=1

# Systemd log identifier used by this script, so that log messages
# recorded by this script can then be isolated from the mass with:
#
# > journalctl SYSLOG_IDENTIFIER=backdrop-configure-httpd
declare -r identifier='backdrop-install'

# Check environment variables required by this script are set.
if ! test -v SKIP_BACKDROP_INSTALLATION; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The SKIP_BACKDROP_INSTALLATION environment variable has not been set."
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
elif ! test -v BACKDROP_DATABASE_HOST; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_DATABASE_HOST environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_DATABASE_PREFIX; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_DATABASE_PREFIX environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_ACCOUNT_NAME; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_ACCOUNT_NAME environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_ACCOUNT_PASSWORD; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_ACCOUNT_PASSWORD environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_ACCOUNT_MAIL; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_ACCOUNT_MAIL environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_CLEAN_URL; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_CLEAN_URL environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_LANGCODE; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_LANGCODE environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_SITE_MAIL; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_SITE_MAIL environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
elif ! test -v BACKDROP_SITE_NAME; then
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "The BACKDROP_SITE_NAME environment variable has not been set."
	exit $EXIT_UNSET_ENVIRONMENT_VARIABLE
else
	systemd-cat \
		--identifier=$identifier \
		echo "All environment variables are set."
fi

# Exit if backdrop installation is to be skipped.
if [ "$SKIP_BACKDROP_INSTALLATION" = true ]; then
	systemd-cat --identifier=$identifier --priority=notice \
		echo "Skipping backdrop installation because SKIP_BACKDROP_INSTALLATION=$SKIP_BACKDROP_INSTALLATION."
	exit $EXIT_OK
fi

# Install backdrop via the command line.
/usr/bin/php /usr/share/backdrop/core/scripts/install.sh \
	--root=/usr/share/backdrop \
	--account-mail="$BACKDROP_ACCOUNT_MAIL" \
	--account-name="$BACKDROP_ACCOUNT_NAME" \
	--account-pass="$BACKDROP_ACCOUNT_PASSWORD" \
	--clean-url="$BACKDROP_CLEAN_URL" \
	--db-url="mysql://$BACKDROP_DATABASE_USER:$BACKDROP_DATABASE_PASSWORD@$BACKDROP_DATABASE_HOST/$BACKDROP_DATABASE_NAME" \
	--langcode="$BACKDROP_LANGCODE" \
	--site-mail="$BACKDROP_SITE_MAIL" \
	--site-name="$BACKDROP_SITE_NAME"
