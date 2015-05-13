# pjlib/build/os-auto.mak.  Generated from os-auto.mak.in by configure.

# Determine OS specific files
AC_OS_OBJS=ioqueue_select.o file_access_unistd.o file_io_ansi.o os_core_unix.o os_error_unix.o os_time_unix.o os_timestamp_posix.o os_info_iphone.o guid_simple.o os_core_darwin.o

#
# PJLIB_OBJS specified here are object files to be included in PJLIB
# (the library) for this specific operating system. Object files common 
# to all operating systems should go in Makefile instead.
#
export PJLIB_OBJS +=	$(AC_OS_OBJS) \
			addr_resolv_sock.o \
			log_writer_stdout.o \
			os_timestamp_common.o \
			pool_policy_malloc.o sock_bsd.o sock_select.o

#
# TEST_OBJS are operating system specific object files to be included in
# the test application.
#
export TEST_OBJS +=	main.o

#
# Additional LDFLAGS for pjlib-test
#
export TEST_LDFLAGS += -O2 -arch armv7 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.1.sdk -framework AudioToolbox -framework Foundation -lbz2 -lz -lpthread  -framework CoreAudio -framework CoreFoundation -framework AudioToolbox -framework CFNetwork -framework UIKit -framework AVFoundation -framework UIKit -framework CoreGraphics -framework QuartzCore -framework CoreVideo -framework CoreMedia 

#
# TARGETS are make targets in the Makefile, to be executed for this given
# operating system.
#
export TARGETS	    =	pjlib pjlib-test



