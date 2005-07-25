###########################################################
#
# mailman
#
###########################################################

# You must replace "mailman" and "MAILMAN" with the lower case name and
# upper case name of your new package.  Some places below will say
# "Do not change this" - that does not include this global change,
# which must always be done to ensure we have unique names.

#
# MAILMAN_VERSION, MAILMAN_SITE and MAILMAN_SOURCE define
# the upstream location of the source code for the package.
# MAILMAN_DIR is the directory which is created when the source
# archive is unpacked.
# MAILMAN_UNZIP is the command used to unzip the source.
# It is usually "zcat" (for .gz) or "bzcat" (for .bz2)
#
# You should change all these variables to suit your package.
# Please make sure that you add a description, and that you
# list all your packages' dependencies, seperated by commas.
# 
# If you list yourself as MAINTAINER, please give a valid email
# address, and indicate your irc nick if it cannot be easily deduced
# from your name or email address.  If you leave MAINTAINER set to
# "NSLU2 Linux" other developers will feel free to edit.
#
MAILMAN_SITE=http://dl.sourceforge.net/sourceforge/mailman
MAILMAN_VERSION=2.1.6
MAILMAN_SOURCE=mailman-$(MAILMAN_VERSION).tgz
MAILMAN_DIR=mailman-$(MAILMAN_VERSION)
MAILMAN_UNZIP=zcat
MAILMAN_MAINTAINER=NSLU2 Linux <nslu2-linux@yahoogroups.com>
MAILMAN_DESCRIPTION=the GNU Mailing List Manager.
MAILMAN_SECTION=misc
MAILMAN_PRIORITY=optional
MAILMAN_DEPENDS=python
MAILMAN_CONFLICTS=

#
# MAILMAN_IPK_VERSION should be incremented when the ipk changes.
#
MAILMAN_IPK_VERSION=1

#
# MAILMAN_CONFFILES should be a list of user-editable files
#MAILMAN_CONFFILES=/opt/etc/mailman.conf /opt/etc/init.d/SXXmailman

#
# MAILMAN_PATCHES should list any patches, in the the order in
# which they should be applied to the source code.
#
MAILMAN_PATCHES=$(MAILMAN_SOURCE_DIR)/src-configure.in.patch
#$(MAILMAN_SOURCE_DIR)/configure.in.patch

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
MAILMAN_CPPFLAGS=
MAILMAN_LDFLAGS=

#
# MAILMAN_BUILD_DIR is the directory in which the build is done.
# MAILMAN_SOURCE_DIR is the directory which holds all the
# patches and ipkg control files.
# MAILMAN_IPK_DIR is the directory in which the ipk is built.
# MAILMAN_IPK is the name of the resulting ipk files.
#
# You should not change any of these variables.
#
MAILMAN_BUILD_DIR=$(BUILD_DIR)/mailman
MAILMAN_SOURCE_DIR=$(SOURCE_DIR)/mailman
MAILMAN_IPK_DIR=$(BUILD_DIR)/mailman-$(MAILMAN_VERSION)-ipk
MAILMAN_IPK=$(BUILD_DIR)/mailman_$(MAILMAN_VERSION)-$(MAILMAN_IPK_VERSION)_$(TARGET_ARCH).ipk

#
# This is the dependency on the source code.  If the source is missing,
# then it will be fetched from the site using wget.
#
$(DL_DIR)/$(MAILMAN_SOURCE):
	$(WGET) -P $(DL_DIR) $(MAILMAN_SITE)/$(MAILMAN_SOURCE)

#
# The source code depends on it existing within the download directory.
# This target will be called by the top level Makefile to download the
# source code's archive (.tar.gz, .bz2, etc.)
#
mailman-source: $(DL_DIR)/$(MAILMAN_SOURCE) $(MAILMAN_PATCHES)

#
# This target unpacks the source code in the build directory.
# If the source archive is not .tar.gz or .tar.bz2, then you will need
# to change the commands here.  Patches to the source code are also
# applied in this target as required.
#
# This target also configures the build within the build directory.
# Flags such as LDFLAGS and CPPFLAGS should be passed into configure
# and NOT $(MAKE) below.  Passing it to configure causes configure to
# correctly BUILD the Makefile with the right paths, where passing it
# to Make causes it to override the default search paths of the compiler.
#
# If the compilation of the package requires other packages to be staged
# first, then do that first (e.g. "$(MAKE) <bar>-stage <baz>-stage").
#
$(MAILMAN_BUILD_DIR)/.configured: $(DL_DIR)/$(MAILMAN_SOURCE) $(MAILMAN_PATCHES)
	#$(MAKE) <bar>-stage <baz>-stage
	rm -rf $(BUILD_DIR)/$(MAILMAN_DIR) $(MAILMAN_BUILD_DIR)
	$(MAILMAN_UNZIP) $(DL_DIR)/$(MAILMAN_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	cat $(MAILMAN_PATCHES) | patch -d $(BUILD_DIR)/$(MAILMAN_DIR) -p1
	mv $(BUILD_DIR)/$(MAILMAN_DIR) $(MAILMAN_BUILD_DIR)
	(cd $(MAILMAN_BUILD_DIR); \
		autoconf configure.in > configure; \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(MAILMAN_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(MAILMAN_LDFLAGS)" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=/opt/lib/mailman \
		--with-var-prefix=/opt/var/mailman \
		--with-python=`type -p python2.4` \
		--with-username=root \
		--with-groupname=root \
		--without-permcheck \
		--disable-nls \
		; \
		find build -type f | xargs sed -i -e 's:^#!.*:#! /opt/bin/python:' \
	)
	touch $(MAILMAN_BUILD_DIR)/.configured

mailman-unpack: $(MAILMAN_BUILD_DIR)/.configured

#
# This builds the actual binary.
#
$(MAILMAN_BUILD_DIR)/.built: $(MAILMAN_BUILD_DIR)/.configured
	rm -f $(MAILMAN_BUILD_DIR)/.built
	$(MAKE) -C $(MAILMAN_BUILD_DIR)
	touch $(MAILMAN_BUILD_DIR)/.built

#
# This is the build convenience target.
#
mailman: $(MAILMAN_BUILD_DIR)/.built

#
# If you are building a library, then you need to stage it too.
#
$(MAILMAN_BUILD_DIR)/.staged: $(MAILMAN_BUILD_DIR)/.built
	rm -f $(MAILMAN_BUILD_DIR)/.staged
	$(MAKE) -C $(MAILMAN_BUILD_DIR) DESTDIR=$(STAGING_DIR) install
	touch $(MAILMAN_BUILD_DIR)/.staged

mailman-stage: $(MAILMAN_BUILD_DIR)/.staged

#
# This rule creates a control file for ipkg.  It is no longer
# necessary to create a seperate control file under sources/mailman
#
$(MAILMAN_IPK_DIR)/CONTROL/control:
	@install -d $(MAILMAN_IPK_DIR)/CONTROL
	@rm -f $@
	@echo "Package: mailman" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(MAILMAN_PRIORITY)" >>$@
	@echo "Section: $(MAILMAN_SECTION)" >>$@
	@echo "Version: $(MAILMAN_VERSION)-$(MAILMAN_IPK_VERSION)" >>$@
	@echo "Maintainer: $(MAILMAN_MAINTAINER)" >>$@
	@echo "Source: $(MAILMAN_SITE)/$(MAILMAN_SOURCE)" >>$@
	@echo "Description: $(MAILMAN_DESCRIPTION)" >>$@
	@echo "Depends: $(MAILMAN_DEPENDS)" >>$@
	@echo "Conflicts: $(MAILMAN_CONFLICTS)" >>$@

#
# This builds the IPK file.
#
# Binaries should be installed into $(MAILMAN_IPK_DIR)/opt/sbin or $(MAILMAN_IPK_DIR)/opt/bin
# (use the location in a well-known Linux distro as a guide for choosing sbin or bin).
# Libraries and include files should be installed into $(MAILMAN_IPK_DIR)/opt/{lib,include}
# Configuration files should be installed in $(MAILMAN_IPK_DIR)/opt/etc/mailman/...
# Documentation files should be installed in $(MAILMAN_IPK_DIR)/opt/doc/mailman/...
# Daemon startup scripts should be installed in $(MAILMAN_IPK_DIR)/opt/etc/init.d/S??mailman
#
# You may need to patch your application to make it use these locations.
#
$(MAILMAN_IPK): $(MAILMAN_BUILD_DIR)/.built
	rm -rf $(MAILMAN_IPK_DIR) $(BUILD_DIR)/mailman_*_$(TARGET_ARCH).ipk
	$(MAKE) -C $(MAILMAN_BUILD_DIR) DESTDIR=$(MAILMAN_IPK_DIR) install
	$(STRIP_COMMAND) $(MAILMAN_IPK_DIR)/opt/lib/mailman/cgi-bin/*
	$(STRIP_COMMAND) $(MAILMAN_IPK_DIR)/opt/lib/mailman/mail/mailman
#	install -d $(MAILMAN_IPK_DIR)/opt/etc/
#	install -m 644 $(MAILMAN_SOURCE_DIR)/mailman.conf $(MAILMAN_IPK_DIR)/opt/etc/mailman.conf
#	install -d $(MAILMAN_IPK_DIR)/opt/etc/init.d
#	install -m 755 $(MAILMAN_SOURCE_DIR)/rc.mailman $(MAILMAN_IPK_DIR)/opt/etc/init.d/SXXmailman
	$(MAKE) $(MAILMAN_IPK_DIR)/CONTROL/control
#	install -m 755 $(MAILMAN_SOURCE_DIR)/postinst $(MAILMAN_IPK_DIR)/CONTROL/postinst
#	install -m 755 $(MAILMAN_SOURCE_DIR)/prerm $(MAILMAN_IPK_DIR)/CONTROL/prerm
#	echo $(MAILMAN_CONFFILES) | sed -e 's/ /\n/g' > $(MAILMAN_IPK_DIR)/CONTROL/conffiles
	cd $(BUILD_DIR); $(IPKG_BUILD) $(MAILMAN_IPK_DIR)

#
# This is called from the top level makefile to create the IPK file.
#
mailman-ipk: $(MAILMAN_IPK)

#
# This is called from the top level makefile to clean all of the built files.
#
mailman-clean:
	-$(MAKE) -C $(MAILMAN_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
mailman-dirclean:
	rm -rf $(BUILD_DIR)/$(MAILMAN_DIR) $(MAILMAN_BUILD_DIR) $(MAILMAN_IPK_DIR) $(MAILMAN_IPK)
