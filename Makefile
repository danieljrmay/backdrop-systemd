#!/usr/bin/make -f
#
# backdrop-systemd GNU Makefile
#
# See: https://www.gnu.org/software/make/manual
#
# Copyright (c) 2022 Daniel J. R. May
#

# Makefile command variables
BUILDAH:=/usr/bin/buildah
DNF_INSTALL:=/usr/bin/dnf --assumeyes install
INSTALL=/usr/bin/install
INSTALL_DATA=$(INSTALL) --mode=644 -D
INSTALL_DIR=$(INSTALL) --directory
INSTALL_PROGRAM=$(INSTALL) --mode=755 -D
PODMAN:=/usr/bin/podman
SHELLCHECK:=/usr/bin/shellcheck
SHELLCHECK_X:=$(SHELLCHECK) --external-sources

# Standard Makefile installation directories.
#
# The following are the standard GNU/RPM values which are defined in
# /usr/lib/rpm/macros. See
# http://www.gnu.org/software/make/manual/html_node/Directory-Variables.html
# for more information.
prefix=/usr
exec_prefix=$(prefix)
bindir=$(exec_prefix)/bin
datadir=$(prefix)/share
includedir=$(prefix)/include
infodir=$(prefix)/info
libdir=$(exec_prefix)/lib
libexecdir=$(exec_prefix)/libexec
localstatedir=$(prefix)/var
mandir=$(prefix)/man
rpmconfigdir=$(libdir)/rpm
sbindir=$(exec_prefix)/sbin
sharedstatedir=$(prefix)/com
sysconfdir=$(prefix)/etc

# Fedora installation directory overrides.
#
# We override some of the previous GNU/RPM default values with those
# values suiteable for a Fedora/RedHat/CentOS linux system, as defined
# in /usr/lib/rpm/redhat/macros.
sysconfdir=/etc
defaultdocdir=/usr/share/doc
infodir=/usr/share/info
localstatedir=/var
mandir=/usr/share/man
sharedstatedir=$(localstatedir)/lib
unitdir=$(libdir)/systemd/system

# Makefile parameter variables
bash_scripts=$(wildcard src/*/*.bash)
env_scripts=$(wildcard src/*/*.env)
name:=backdrop-systemd
requirements:=buildah gawk make mock podman rpm-build rpmlint ShellCheck
testdestdir=testdestdir
version:=0.1
dist_name:=$(name)-$(version)
tarball:=$(dist_name).tar.xz

.PHONY: all
all:
	$(info all:)

.PHONY: lint
lint:
	$(info lint:)
	$(SHELLCHECK_X) $(bash_scripts) $(env_scripts)

testdestdir:
	mkdir -p $(testdestdir)
	$(eval DESTDIR:=$(testdestdir))

.PHONY: testinstall
testinstall: | testdestdir install installcheck

.PHONY: install
install:
	$(info install:)
	$(INSTALL_PROGRAM) src/backdrop-configure-httpd/backdrop-configure-httpd.bash $(DESTDIR)$(bindir)/backdrop-configure-httpd
	$(INSTALL_DATA) src/backdrop-configure-httpd/backdrop-configure-httpd.service $(DESTDIR)$(unitdir)/backdrop-configure-httpd.service
	$(INSTALL_PROGRAM) src/backdrop-configure-mariadb/backdrop-configure-mariadb.bash $(DESTDIR)$(bindir)/backdrop-configure-mariadb
	$(INSTALL_DATA) src/backdrop-configure-mariadb/backdrop-configure-mariadb.service $(DESTDIR)$(unitdir)/backdrop-configure-mariadb.service
	$(INSTALL_PROGRAM) src/backdrop-install/backdrop-install.bash $(DESTDIR)$(bindir)/backdrop-install
	$(INSTALL_DATA) src/backdrop-install/backdrop-install.service $(DESTDIR)$(unitdir)/backdrop-install.service

.PHONY: installcheck
installcheck:
	$(info installcheck:)
	test -x $(DESTDIR)$(bindir)/backdrop-configure-httpd
	test -r $(DESTDIR)$(unitdir)/backdrop-configure-httpd.service
	test -x $(DESTDIR)$(bindir)/backdrop-configure-mariadb
	test -r $(DESTDIR)$(unitdir)/backdrop-configure-mariadb.service
	test -x $(DESTDIR)$(bindir)/backdrop-install
	test -r $(DESTDIR)$(unitdir)/backdrop-install.service

.PHONY: uninstall
uninstall:
	$(info uninstall:)
	rm -f $(DESTDIR)$(bindir)/backdrop-configure-httpd
	rm -f $(DESTDIR)$(unitdir)/backdrop-configure-httpd.service
	rm -f $(DESTDIR)$(bindir)/backdrop-configure-mariadb
	rm -f $(DESTDIR)$(unitdir)/backdrop-configure-mariadb.service
	rm -f $(DESTDIR)$(bindir)/backdrop-install
	rm -f $(DESTDIR)$(unitdir)/backdrop-install.service

.PHONY: dist
dist: $(tarball)

$(tarball):
	mkdir $(dist_name)
	cp --recursive LICENSE Makefile README.md src test TODO.md $(dist_name)
	tar --create --file $(tarball) --xz $(dist_name)

.PHONY: requirements
requirements:
	$(DNF_INSTALL) $(requirements)

.PHONY: clean
clean:
	$(info clean:)
	rm -rf $(dist_name)

.PHONY: distclean
distclean: clean
	$(info distclean:)
	rm -rf $(testdestdir) $(tarball)

.PHONY: help
help:
	$(info help:)
	$(info Usage: make TARGET [VAR1=VALUE VAR2=VALUE])
	$(info )
	$(info Targets:)
	$(info   all                    The default target, build the RPM.)
	$(info   lint                   Lint some of the source files.)
	$(info   clean                  Clean up all generated RPM files.)
	$(info   distclean              Clean up all generated files.)
	$(info   requirements           Install all packaging development and testing requirements, requires sudo.)
	$(info   help                   Display this help message.)
	$(info   printvars              Print variable values (useful for debugging).)
	$(info   printmakevars          Print the Make variable values (useful for debugging).)
	$(info )
	$(info For more information see the README.md file.)
	@:

.PHONY: printvars
printvars:
	$(info printvars:)
	$(info BUILDAH=$(BUILDAH))
	$(info DNF_INSTALL=$(DNF_INSTALL))
	$(info PODMAN=$(PODMAN))
	$(info SHELLCHECK=$(SHELLCHECK))
	$(info SHELLCHECK_X=$(SHELLCHECK_X))
	$(info requirements=$(requirements))
	$(info bash_scripts=$(bash_scripts))
	$(info version=$(version))
	$(info mock_root=$(mock_root))
	$(info mock_resultdir=$(mock_resultdir))
	$(info srpm=$(srpm))
	$(info rpm=$(rpm))
	$(info image=$(image))
	$(info container=$(container))
	@:

.PHONY: printmakevars
printmakevars:
	$(info printmakevars:)
	$(info $(.VARIABLES))
	@:
