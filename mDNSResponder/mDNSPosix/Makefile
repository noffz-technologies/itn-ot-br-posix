# -*- tab-width: 4 -*-
#
# Copyright (c) 2002-2021 Apple Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# IMPORTANT NOTE: This is a Makefile for *GNU make*
# On some systems, a different program may be the default "make" command.
# If "make os=xxx" gives lots of errors like "Missing dependency operator",
# then try typing "gmake os=xxx" instead.
#
# This Makefile builds an mDNSResponder daemon and a libdns_sd.so shared library
# for Linux. It also builds several example programs for embedded systems.
#
# Make with no arguments to build all production targets.
# 'make DEBUG=1' to build debugging targets.
# 'make clean' or 'make clean DEBUG=1' to delete prod/debug objects & targets
# 'sudo make install [DEBUG=1]' to install mdnsd daemon and libdns_sd.
#
# Notes:
# $@ means "The file name of the target of the rule"
# $< means "The name of the first prerequisite"
# $* means "The stem with which an implicit rule matches"
# $+ means "The names of all the prerequisites, with spaces between them, exactly as given"
# For more magic automatic variables, see
# <http://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html>

#############################################################################

DESTDIR ?= /

LIBVERS = 1

COREDIR = ../mDNSCore
SHAREDDIR ?= ../mDNSShared
UTILDIR ?= ../mDNSShared/utilities
DSODIR ?= ../DSO
SERVICEREGISTRATIONDIR ?= ../ServiceRegistration
JDK = /usr/jdk

SYSTEM := $(shell uname -s)
ifeq ($(SYSTEM), Darwin)
  os=x
else ifeq ($(SYSTEM), Linux)
  os=linux
endif

CC = cc
BISON = bison
FLEX = flex
ST = strip
LD = ld
SOOPTS = -shared
CP = cp
RM = rm
LN = ln -s -f
CFLAGS_COMMON = -I$(COREDIR) -I$(SHAREDDIR) -I$(UTILDIR) -I$(DSODIR) -I$(SERVICEREGISTRATIONDIR) -I$(OBJDIR) -fwrapv -W -Wall -DPOSIX_BUILD -DPID_FILE=\"/var/run/mdnsd.pid\" -DMDNS_UDS_SERVERPATH=\"/var/run/mdnsd\"
CFLAGS_PTHREAD =
LINKOPTS =
LINKOPTS_PTHREAD = -lpthread
LDSUFFIX = so
JAVACFLAGS_OS = -fPIC -shared -ldns_sd

# Set up diverging paths for debug vs. prod builds
ifeq "$(DEBUG)" "1"
CFLAGS_DEBUGGING = -g -DMDNS_DEBUGMSGS=2
OBJDIR = objects/debug
BUILDDIR = build/debug
STRIP = echo
else
ifeq "$(DEBUGSYMS)" "1"
CFLAGS_DEBUGGING = -g -DMDNS_DEBUGMSGS=0
OBJDIR = objects/prod
BUILDDIR = build/prod
STRIP = echo
else
# We use -Os for two reasons:
# 1. We want to make small binaries, suitable for putting into hardware devices
# 2. Some of the code analysis warnings only work when some form of optimization is enabled
CFLAGS_DEBUGGING = -g -DMDNS_DEBUGMSGS=0
OBJDIR ?= objects/prod
BUILDDIR ?= build/prod
STRIP = $(ST) -S
endif
endif

# Configure per-OS peculiarities
ifeq ($(os),solaris)
CFLAGS_DEBUGGING = -O0 -DMDNS_DEBUGMSGS=0
CFLAGS_OS = -DNOT_HAVE_DAEMON -DNOT_HAVE_SA_LEN -DNOT_HAVE_SOCKLEN_T -DNOT_HAVE_IF_NAMETOINDEX \
	 -DLOG_PERROR=0 -D_XPG4_2 -D__EXTENSIONS__ -DHAVE_BROKEN_RECVIF_NAME -DTARGET_OS_SOLARIS
CC = gcc
LD = gcc
SOOPTS = -shared
LINKOPTS = -lsocket -lnsl -lresolv
JAVACFLAGS_OS += -I$(JDK)/include/solaris
ifneq ($(DEBUG),1)
STRIP = $(ST)
endif
else

# any target that contains the string "linux"
ifeq ($(findstring linux,$(os)),linux)
ifeq ($(tls), no)
CFLAGS_OS = -D_GNU_SOURCE -DHAVE_IPV6 -DNOT_HAVE_SA_LEN -DUSES_NETLINK -DHAVE_LINUX -DTARGET_OS_LINUX -ftabstop=4 -Wno-expansion-to-defined
TLSOBJS =
else
CFLAGS_OS = -D_GNU_SOURCE -DHAVE_IPV6 -DNOT_HAVE_SA_LEN -DUSES_NETLINK -DHAVE_LINUX -DTARGET_OS_LINUX -DPOSIX_HAS_TLS -ftabstop=4 -Wno-expansion-to-defined
TLSOBJS = $(OBJDIR)/mbedtls.c.o -lmbedtls -lmbedcrypto
endif
LD = $(CC)
SOOPTS = -shared
FLEXFLAGS_OS = -l
JAVACFLAGS_OS += -I$(JDK)/include/linux

# uClibc does not support Name Service Switch
ifneq ($(os),linux-uclibc)
OPTIONALTARG = nss_mdns
OPTINSTALL   = InstalledNSS
endif
else

ifeq ($(os),netbsd)
CFLAGS_OS =
LDCONFIG = ldconfig
else

ifeq ($(os),freebsd)
# If not already defined, set LOCALBASE to /usr/local
LOCALBASE?=$(DESTDIR)/usr/local
INSTBASE=$(LOCALBASE)
CFLAGS_OS = -DHAVE_IPV6
# FreeBSD 4 requires threaded code to be compiled and linked using the "-pthread" option,
# and requires that the "-lpthread" link option NOT be used
# This appies only to FreeBSD -- "man cc" on FreeBSD says:
#   FreeBSD SPECIFIC OPTIONS
#     -pthread
#       Link a user-threaded process against libc_r instead of libc.
CFLAGS_PTHREAD   = -pthread -D_THREAD_SAFE
LINKOPTS_PTHREAD = -pthread
JAVACFLAGS_OS += -I$(JDK)/include/freebsd
LDCONFIG = ldconfig
else

ifeq ($(os),openbsd)
CFLAGS_OS = -DHAVE_BROKEN_RECVDSTADDR
LDCONFIG = ldconfig
else

ifeq ($(os),x)
# We have to define __MAC_OS_X_VERSION_MIN_REQUIRED=__MAC_OS_X_VERSION_10_4 or on Leopard
# we get build failures: ‘daemon’ is deprecated (declared at /usr/include/stdlib.h:283)
CFLAGS_OS = -DHAVE_IPV6 -no-cpp-precomp -Werror -Wno-declaration-after-statement -Wno-unused-but-set-variable \
	-D__MAC_OS_X_VERSION_MIN_REQUIRED=__MAC_OS_X_VERSION_10_4 \
	-DHAVE_STRLCPY=1 -DTARGET_OS_MAC \
	-D__APPLE_USE_RFC_2292 #-Wunreachable-code
CC = gcc
LD = $(CC)
SOOPTS = -dynamiclib
LINKOPTS = -lSystem
LDSUFFIX = dylib
JDK = /System/Library/Frameworks/JavaVM.framework/Home
JAVACFLAGS_OS = -dynamiclib -I/System/Library/Frameworks/JavaVM.framework/Headers -framework JavaVM
OPTIONALTARG = dnsextd
else

$(error ERROR: Must specify target OS on command-line, e.g. "make os=x [target]".\
Supported operating systems include: x, linux, linux-uclibc, netbsd, freebsd, openbsd, solaris)
endif
endif
endif
endif
endif
endif

NSSLIBNAME  := libnss_mdns
NSSVERSION  := 0.2
NSSLIBFILE  := $(NSSLIBNAME)-$(NSSVERSION).so
NSSLINKNAME := $(NSSLIBNAME).so.2
NSSINSTPATH := $(DESTDIR)/lib

# If not otherwise defined, we install into /usr/lib and /usr/include
# and our startup script is called mdns (e.g. /etc/init.d/mdns)
ETCBASE?=$(DESTDIR)/etc
INSTBASE?=$(DESTDIR)/usr
STARTUPSCRIPTNAME?=mdns

ifeq ($(HAVE_IPV6),1)
CFLAGS_OS += -DHAVE_IPV6=1
else
ifeq ($(HAVE_IPV6),0)
CFLAGS_OS += -DHAVE_IPV6=0
endif
endif

# If directory /usr/share/man exists, then we install man pages into that, else /usr/man
ifeq ($(wildcard /usr/share/man), /usr/share/man)
MANPATH := $(DESTDIR)/usr/share/man
else
MANPATH := $(DESTDIR)/usr/man
endif

# If directories /etc/init.d/rc*.d exist, then we install into that (Suse)
ifeq ($(wildcard /etc/init.d/rc2.d/), /etc/init.d/rc2.d/)
STARTUPSCRIPTDIR = $(DESTDIR)/etc/init.d
RUNLEVELSCRIPTSDIR = $(DESTDIR)/etc/init.d
else
# Else if directory /etc/rc.d/init.d/ exists, then we install into that (old Linux)
ifeq ($(wildcard /etc/rc.d/init.d/), /etc/rc.d/init.d/)
STARTUPSCRIPTDIR = $(DESTDIR)/etc/rc.d/init.d
RUNLEVELSCRIPTSDIR = $(DESTDIR)/etc/rc.d
else
# Else if directory /etc/init.d/ exists, then we install into that (new Linux)
ifeq ($(wildcard /etc/init.d/), /etc/init.d/)
STARTUPSCRIPTDIR = $(DESTDIR)/etc/init.d
RUNLEVELSCRIPTSDIR = $(DESTDIR)/etc
else
# Else install into /etc/rc.d/ (*BSD)
STARTUPSCRIPTDIR = $(INSTBASE)/etc/rc.d
endif
endif
endif

MDNSCFLAGS = $(CFLAGS) $(CFLAGS_COMMON) $(CFLAGS_OS) $(CFLAGS_DEBUGGING)

#############################################################################

all: setup Daemon libdns_sd Clients SAClient SAResponder SAProxyResponder NetMonitor $(OPTIONALTARG)

install: setup InstalledStartup InstalledDaemon InstalledLib InstalledManPages InstalledClients $(OPTINSTALL)

# 'setup' sets up the build directory structure the way we want
setup:
	@if test ! -d $(OBJDIR)   ; then mkdir -p $(OBJDIR)   ; fi
	@if test ! -d $(BUILDDIR) ; then mkdir -p $(BUILDDIR) ; fi

# clean removes targets and objects
clean:
	@if test -d $(OBJDIR)   ; then rm -r $(OBJDIR)   ; fi
	@if test -d $(BUILDDIR) ; then rm -r $(BUILDDIR) ; fi
	@$(MAKE) -C ../Clients clean

#############################################################################

# daemon target builds the daemon
DAEMONOBJS = $(OBJDIR)/PosixDaemon.c.o $(OBJDIR)/mDNSPosix.c.o $(OBJDIR)/mDNSUNP.c.o $(OBJDIR)/mDNS.c.o \
             $(OBJDIR)/DNSDigest.c.o $(OBJDIR)/uDNS.c.o $(OBJDIR)/DNSCommon.c.o $(OBJDIR)/uds_daemon.c.o \
             $(OBJDIR)/mDNSDebug.c.o $(OBJDIR)/dnssd_ipc.c.o $(OBJDIR)/GenLinkedList.c.o \
             $(OBJDIR)/PlatformCommon.c.o $(OBJDIR)/ClientRequests.c.o \
             $(OBJDIR)/dso.c.o $(OBJDIR)/dso-transport.c.o $(OBJDIR)/dnssd_clientshim.c.o \
             $(TLSOBJS) $(OBJDIR)/mdns_addr_tailq.c.o $(OBJDIR)/misc_utilities.c.o

# dnsextd target build dnsextd
DNSEXTDOBJ = $(OBJDIR)/mDNSPosix.c.o $(OBJDIR)/mDNSUNP.c.o $(OBJDIR)/mDNSDebug.c.o $(OBJDIR)/GenLinkedList.c.o $(OBJDIR)/DNSDigest.c.o \
             $(OBJDIR)/DNSCommon.c.o $(OBJDIR)/PlatformCommon.c.o $(OBJDIR)/dnsextd_parser.y.o $(OBJDIR)/dnsextd_lexer.l.o

Daemon: setup $(BUILDDIR)/mdnsd
	@echo "Responder daemon done"

$(BUILDDIR)/mdnsd: $(DAEMONOBJS)
	$(CC) -o $@ $+ $(LINKOPTS)
	$(STRIP) $@

# libdns_sd target builds the client library
libdns_sd: setup $(BUILDDIR)/libdns_sd.$(LDSUFFIX)
	@echo "Client library done"

CLIENTLIBOBJS = $(OBJDIR)/dnssd_clientlib.c.so.o $(OBJDIR)/dnssd_clientstub.c.so.o $(OBJDIR)/dnssd_ipc.c.so.o $(OBJDIR)/dnssd_errstring.c.so.o

$(BUILDDIR)/libdns_sd.$(LDSUFFIX): $(CLIENTLIBOBJS)
	$(LD) $(SOOPTS) $(LINKOPTS) -o $@ $+
	$(STRIP) $@

Clients: setup ../Clients/build/dns-sd
	@echo "Clients done"

../Clients/build/dns-sd: ../Clients/dns-sd.c libdns_sd
	$(MAKE) -C ../Clients DEBUG=$(DEBUG) SUPMAKE_CFLAGS="$(MDNSCFLAGS)"

# nss_mdns target builds the Name Service Switch module
nss_mdns: setup $(BUILDDIR)/$(NSSLIBFILE)
	@echo "Name Service Switch module done"

$(BUILDDIR)/$(NSSLIBFILE): $(CLIENTLIBOBJS) $(OBJDIR)/nss_mdns.c.so.o
	$(LD) $(SOOPTS) $(LINKOPTS) -o $@ $+
	$(STRIP) $@

#############################################################################

# The Install targets place built stuff in their proper places
InstalledDaemon: $(INSTBASE)/sbin/mdnsd
	@echo $+ " installed"

InstalledLib: $(INSTBASE)/lib/libdns_sd.$(LDSUFFIX).$(LIBVERS) $(INSTBASE)/include/dns_sd.h
	@echo $+ " installed"

InstalledStartup: $(STARTUPSCRIPTDIR)/$(STARTUPSCRIPTNAME)
	@echo $+ " installed"

InstalledManPages: $(MANPATH)/man8/mdnsd.8
	@echo $+ " installed"

InstalledClients: $(INSTBASE)/bin/dns-sd
	@echo $+ " installed"

InstalledNSS: $(NSSINSTPATH)/$(NSSLINKNAME) $(DESTDIR)/etc/nss_mdns.conf $(MANPATH)/man5/nss_mdns.conf.5 $(MANPATH)/man8/libnss_mdns.8
	@echo $+ " installed"

# Note: If daemon already installed, we make sure it's stopped before overwriting it
$(INSTBASE)/sbin/mdnsd: $(BUILDDIR)/mdnsd $(STARTUPSCRIPTDIR)/$(STARTUPSCRIPTNAME)
	if test -x $@; then $(STARTUPSCRIPTDIR)/$(STARTUPSCRIPTNAME) stop; fi
	@mkdir -p $(INSTBASE)/sbin
	$(CP) $< $@
	$(STARTUPSCRIPTDIR)/$(STARTUPSCRIPTNAME) start

$(INSTBASE)/lib/libdns_sd.$(LDSUFFIX).$(LIBVERS): $(BUILDDIR)/libdns_sd.$(LDSUFFIX)
	@mkdir -p $(INSTBASE)/lib/
	$(CP) $< $@
	$(LN) $@ $(INSTBASE)/lib/libdns_sd.$(LDSUFFIX)
ifdef LDCONFIG
	# -m means 'merge into existing database', -R means 'rescan directories'
	$(LDCONFIG) -mR
endif

$(INSTBASE)/include/dns_sd.h: $(SHAREDDIR)/dns_sd.h
	@mkdir -p $(INSTBASE)/include/
	$(CP) $< $@

$(STARTUPSCRIPTDIR)/$(STARTUPSCRIPTNAME): mdnsd.sh 
	@mkdir -p $(STARTUPSCRIPTDIR)
	@mkdir -p $(RUNLEVELSCRIPTSDIR)
	$(CP) $< $@
	chmod ugo+x $@
ifdef RUNLEVELSCRIPTSDIR
ifeq ($(wildcard $(RUNLEVELSCRIPTSDIR)/runlevels/default), $(RUNLEVELSCRIPTSDIR)/runlevels/default)
	$(LN) $@ $(RUNLEVELSCRIPTSDIR)/runlevels/default/mdns


#else
#	$(LN) $@ $(RUNLEVELSCRIPTSDIR)/rc2.d/S52mdns
#	$(LN) $@ $(RUNLEVELSCRIPTSDIR)/rc3.d/S52mdns
#	$(LN) $@ $(RUNLEVELSCRIPTSDIR)/rc4.d/S52mdns
#	$(LN) $@ $(RUNLEVELSCRIPTSDIR)/rc5.d/S52mdns
#	$(LN) $@ $(RUNLEVELSCRIPTSDIR)/rc0.d/K16mdns
#	$(LN) $@ $(RUNLEVELSCRIPTSDIR)/rc6.d/K16mdns
endif
endif

$(MANPATH)/man5/%.5: %.5
	mkdir -p $(MANPATH)/man5
	cp $< $@
	chmod 444 $@

$(MANPATH)/man8/%.8: %.8
	mkdir -p $(MANPATH)/man8
	cp $< $@
	chmod 444 $@

$(MANPATH)/man8/mdnsd.8: $(SHAREDDIR)/mDNSResponder.8
	mkdir -p $(MANPATH)/man8
	cp $< $@
	chmod 444 $@

$(INSTBASE)/bin/dns-sd: ../Clients/build/dns-sd
	mkdir -p $(INSTBASE)/bin
	$(CP) $< $@

$(NSSINSTPATH)/$(NSSLINKNAME): $(NSSINSTPATH)/$(NSSLIBFILE)
	mkdir -p $(NSSINSTPATH)
	$(LN) $< $@
	ldconfig

$(NSSINSTPATH)/$(NSSLIBFILE): $(BUILDDIR)/$(NSSLIBFILE)
	mkdir -p $(NSSINSTPATH)
	$(CP) $< $@
	chmod 444 $@

$(DESTDIR)/etc/nss_mdns.conf: nss_mdns.conf
	mkdir -p $(DESTDIR)/etc
	$(CP) $< $@
	chmod 444 $@
# Check the nsswitch.conf file.
# If 'mdns' does not already appear on the "hosts:" line, then add it right before 'dns'
	cp -f $(DESTDIR)/etc/nsswitch.conf $(DESTDIR)/etc/nsswitch.conf.pre-mdns
	sed -e '/\bmdns\b/!s/^\(hosts:.*\)dns\(.*\)/\1mdns dns\2/' $(DESTDIR)/etc/nsswitch.conf.pre-mdns > $(DESTDIR)/etc/nsswitch.conf

#############################################################################

# The following targets build Java wrappers for the dns-sd.h API.
# Note that the JavaForXcode targets are used when building the project for OS X using Xcode

JAVAC = $(JDK)/bin/javac
JAVAH = $(JDK)/bin/javah
JAVADOC = $(JDK)/bin/javadoc
JAR = $(JDK)/bin/jar
JAVACFLAGS = $(MDNSCFLAGS) $(JAVACFLAGS_OS) -I$(JDK)/include

JavaForXcode_: setup $(BUILDDIR)/dns_sd.jar $(PROJECT_DERIVED_FILE_DIR)/DNSSD.java.h
	@echo $@ done

$(PROJECT_DERIVED_FILE_DIR)/DNSSD.java.h: $(OBJDIR)/DNSSD.java.h
	@if test ! -d $(PROJECT_DERIVED_FILE_DIR) ; then mkdir -p $(PROJECT_DERIVED_FILE_DIR) ; fi
	$(CP) $< $@

JavaForXcode_clean:
	@if test -d $(OBJDIR) ; then rm -r $(OBJDIR) ; fi
	@if test -f $(PROJECT_DERIVED_FILE_DIR)/DNSSD.java.h ; then $(RM) $(PROJECT_DERIVED_FILE_DIR)/DNSSD.java.h ; fi
	@if test -f $(BUILDDIR)/dns_sd.jar ; then $(RM) $(BUILDDIR)/dns_sd.jar ; fi
	@echo $@ done

JavaForXcode_installhdrs:
	@echo $@ NOOP

JavaForXcode_install: JavaForXcode_ $(DSTROOT)/$(SYSTEM_LIBRARY_DIR)/Java/Extensions/dns_sd.jar
	@echo $@ done

$(DSTROOT)/$(SYSTEM_LIBRARY_DIR)/Java/Extensions/dns_sd.jar: $(BUILDDIR)/dns_sd.jar
	@if test ! -d $(DSTROOT)/$(SYSTEM_LIBRARY_DIR)/Java/Extensions ; then mkdir -p $(DSTROOT)/$(SYSTEM_LIBRARY_DIR)/Java/Extensions ; fi
	$(CP) $< $@

Java: setup $(BUILDDIR)/dns_sd.jar $(BUILDDIR)/libjdns_sd.$(LDSUFFIX)
	@echo "Java wrappers done"

JAVASRC	= $(SHAREDDIR)/Java
JARCONTENTS =	$(OBJDIR)/com/apple/dnssd/DNSSDService.class \
				$(OBJDIR)/com/apple/dnssd/DNSSDException.class \
				$(OBJDIR)/com/apple/dnssd/DNSRecord.class \
				$(OBJDIR)/com/apple/dnssd/TXTRecord.class \
				$(OBJDIR)/com/apple/dnssd/DNSSDRegistration.class \
				$(OBJDIR)/com/apple/dnssd/BaseListener.class \
				$(OBJDIR)/com/apple/dnssd/BrowseListener.class \
				$(OBJDIR)/com/apple/dnssd/ResolveListener.class \
				$(OBJDIR)/com/apple/dnssd/RegisterListener.class \
				$(OBJDIR)/com/apple/dnssd/QueryListener.class \
				$(OBJDIR)/com/apple/dnssd/DomainListener.class \
				$(OBJDIR)/com/apple/dnssd/RegisterRecordListener.class \
				$(OBJDIR)/com/apple/dnssd/DNSSDRecordRegistrar.class \
				$(OBJDIR)/com/apple/dnssd/DNSSD.class

$(BUILDDIR)/dns_sd.jar: $(JARCONTENTS) setup
	$(JAR) -cf $@ -C $(OBJDIR) com

$(BUILDDIR)/libjdns_sd.$(LDSUFFIX): $(JAVASRC)/JNISupport.c $(OBJDIR)/DNSSD.java.h setup libdns_sd
	$(CC) -o $@ $< $(JAVACFLAGS) -I$(OBJDIR) -L$(BUILDDIR)

$(OBJDIR)/com/apple/dnssd/%.class:	$(JAVASRC)/%.java
	$(JAVAC) -d $(OBJDIR) -classpath $(OBJDIR) $<

$(OBJDIR)/DNSSD.java.h: $(OBJDIR)/com/apple/dnssd/DNSSD.class
	$(JAVAH) -force -classpath $(OBJDIR) -o $@ \
		com.apple.dnssd.AppleDNSSD \
		com.apple.dnssd.AppleBrowser \
		com.apple.dnssd.AppleResolver \
		com.apple.dnssd.AppleRegistration \
		com.apple.dnssd.AppleQuery \
		com.apple.dnssd.AppleDomainEnum \
		com.apple.dnssd.AppleService \
		com.apple.dnssd.AppleDNSRecord \
		com.apple.dnssd.AppleRecordRegistrar

#############################################################################

# The following target builds documentation for the Java wrappers.

JavaDoc: Java setup
	$(JAVADOC) $(JAVASRC)/*.java -classpath $(OBJDIR) -d $(BUILDDIR) -public

#############################################################################

# The following targets build embedded example programs
SPECIALOBJ = $(OBJDIR)/mDNSPosix.c.o $(OBJDIR)/mDNSUNP.c.o $(OBJDIR)/mDNSDebug.c.o $(OBJDIR)/GenLinkedList.c.o \
	$(OBJDIR)/DNSDigest.c.o $(OBJDIR)/uDNS.c.o $(OBJDIR)/DNSCommon.c.o $(OBJDIR)/PlatformCommon.c.o \
	$(OBJDIR)/dso.c.o $(OBJDIR)/dso-transport.c.o $(OBJDIR)/dnssd_clientshim.c.o \
	$(OBJDIR)/mdns_addr_tailq.c.o $(OBJDIR)/misc_utilities.c.o
COMMONOBJ  = $(SPECIALOBJ) $(OBJDIR)/mDNS.c.o
APPOBJ     = $(COMMONOBJ) $(OBJDIR)/ExampleClientApp.c.o

SAClient: setup $(BUILDDIR)/mDNSClientPosix
	@echo "Embedded Standalone Client done"

SAResponder: setup $(BUILDDIR)/mDNSResponderPosix
	@echo "Embedded Standalone Responder done"

SAProxyResponder: setup $(BUILDDIR)/mDNSProxyResponderPosix
	@echo "Embedded Standalone ProxyResponder done"

NetMonitor: setup $(BUILDDIR)/mDNSNetMonitor
	@echo "NetMonitor done"

dnsextd: setup $(BUILDDIR)/dnsextd
	@echo "dnsextd done"

$(BUILDDIR)/mDNSClientPosix:         $(APPOBJ) $(TLSOBJS)     $(OBJDIR)/Client.c.o
	$(CC) $+ -o $@ $(LINKOPTS)

$(BUILDDIR)/mDNSResponderPosix:      $(COMMONOBJ) $(TLSOBJS)  $(OBJDIR)/Responder.c.o
	$(CC) $+ -o $@ $(LINKOPTS)

$(BUILDDIR)/mDNSProxyResponderPosix: $(COMMONOBJ) $(TLSOBJS)  $(OBJDIR)/ProxyResponder.c.o
	$(CC) $+ -o $@ $(LINKOPTS)

$(BUILDDIR)/mDNSNetMonitor:          $(SPECIALOBJ) $(TLSOBJS) $(OBJDIR)/NetMonitor.c.o
	$(CC) $+ -o $@ $(LINKOPTS)

$(OBJDIR)/NetMonitor.c.o:            $(COREDIR)/mDNS.c # Note: NetMonitor.c textually imports mDNS.c

$(BUILDDIR)/dnsextd:                 $(DNSEXTDOBJ) $(OBJDIR)/dnsextd.c.threadsafe.o
	$(CC) $+ -o $@ $(LINKOPTS) $(LINKOPTS_PTHREAD)

#############################################################################

# Implicit rules
$(OBJDIR)/%.c.o:	%.c
	$(CC) $(MDNSCFLAGS) -c -o $@ $<

$(OBJDIR)/%.c.o:	$(COREDIR)/%.c
	$(CC) $(MDNSCFLAGS) -c -o $@ $<

$(OBJDIR)/%.c.o:	$(SHAREDDIR)/%.c
	$(CC) $(MDNSCFLAGS) -c -o $@ $<

$(OBJDIR)/%.c.o:	$(DSODIR)/%.c
	$(CC) $(MDNSCFLAGS) -c -o $@ $<

$(OBJDIR)/%.c.o:	$(UTILDIR)/%.c
	$(CC) $(MDNSCFLAGS) -c -o $@ $<

$(OBJDIR)/%.c.threadsafe.o:	%.c
	$(CC) $(MDNSCFLAGS) $(MDNSCFLAGS_PTHREAD) -D_REENTRANT -c -o $@ $<

$(OBJDIR)/%.c.threadsafe.o:	$(SHAREDDIR)/%.c
	$(CC) $(MDNSCFLAGS) $(MDNSCFLAGS_PTHREAD) -D_REENTRANT -c -o $@ $<

$(OBJDIR)/%.c.so.o:	%.c
	$(CC) $(MDNSCFLAGS) -c -fPIC -o $@ $<

$(OBJDIR)/%.c.so.o:	$(SHAREDDIR)/%.c
	$(CC) $(MDNSCFLAGS) -c -fPIC -o $@ $<

$(OBJDIR)/%.y.o: $(SHAREDDIR)/%.y
	$(BISON)              -o $(OBJDIR)/$*.c -d $<
	$(CC) $(MDNSCFLAGS) -c -o $@ $(OBJDIR)/$*.c

$(OBJDIR)/%.l.o: $(SHAREDDIR)/%.l
	$(FLEX) $(FLEXFLAGS_OS) -i             -o$(OBJDIR)/$*.l.c $<
	$(CC) $(MDNSCFLAGS) -Wno-error -c -o $@ $(OBJDIR)/$*.l.c
