###############################################################
#
# Purpose: Makefile for "M-JPEG Streamer"
# Author.: Tom Stoeveken (TST)
# Version: 0.4
# License: GPL
#
###############################################################

# specifies where to install the binaries after compilation
# to use another directory you can specify it with:
# $ sudo make DESTDIR=/some/path install
DESTDIR = /usr/local

# set the compiler to use
CC = arm-linux-gcc

# general compile flags, enable all warnings to make compile more verbose
CFLAGS += -O2 -DLINUX -D_GNU_SOURCE -Wall
#CFLAGS += -DDEBUG

# we are using the libraries "libpthread" and "libdl"
# libpthread is used to run several tasks (virtually) in parallel
# libdl is used to load the plugins (shared objects) at runtime
LFLAGS += -lpthread -ldl

# define the name of the program
APP_BINARY = video_web

# define the names and targets of the plugins
PLUGINS = input_uvc.so
PLUGINS += output_http.so

# define the names of object files
OBJECTS=video_web.o utils.o

# this is the first target, thus it will be used implictely if no other target
# was given. It defines that it is dependent on the application target and
# the plugins
all: application plugins

application: $(APP_BINARY)

plugins: $(PLUGINS)

$(APP_BINARY): video_web.c video_web.h video_web.o utils.c utils.h utils.o
	$(CC) $(CFLAGS) $(LFLAGS) $(OBJECTS) -o $(APP_BINARY)
	chmod 755 $(APP_BINARY)

input_uvc.so: video_web.h utils.h
	make -C plugins/input_uvc all
	cp plugins/input_uvc/input_uvc.so .

output_http.so: video_web.h utils.h
	make -C plugins/output_http all
	cp plugins/output_http/output_http.so .


# The viewer plugin requires the SDL library for compilation
# This is very uncommmon on embedded devices, so it is commented out and will
# not be build automatically. If you compile for PC, install libsdl and then
# execute the following command:
# make output_viewer.so

# cleanup
clean:
	make -C plugins/input_uvc $@
	make -C plugins/output_http $@

	rm -f *.a *.o $(APP_BINARY) core *~ *.so *.lo

# useful to make a backup "make tgz"
tgz: clean
	mkdir -p backups
	tar czvf ./backups/video_web_`date +"%Y_%m_%d_%H.%M.%S"`.tgz --exclude backups --exclude .svn *

# install MJPG-streamer and example webpages
install: all
	install --mode=755 $(APP_BINARY) $(DESTDIR)/bin
	install --mode=644 $(PLUGINS) $(DESTDIR)/lib/
	install --mode=755 -d $(DESTDIR)/www
	install --mode=644 -D www/* $(DESTDIR)/www

# remove the files installed above
uninstall:
	rm -f $(DESTDIR)/bin/$(APP_BINARY)
	for plug in $(PLUGINS); do \
	  rm -f $(DESTDIR)/lib/$$plug; \
	done;
