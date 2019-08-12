PROTOC_C ?= protoc-c
PKG_CONFIG ?= pkg-config

DIR_PERM = 0755
LIB_PERM = 0755

# Note: Use "-C .git" to avoid ascending to parent dirs if .git not present
GIT_REVISION_ID = $(shell git -C .git rev-parse --short HEAD 2>/dev/null)
PLUGIN_VERSION ?= $(shell cat VERSION)~git$(GIT_REVISION_ID)

CFLAGS	?= -O2 -g -pipe -Wall
LDFLAGS ?= -Wl,-z,relro

CFLAGS  += -std=c99 -DSIGNALD_PLUGIN_VERSION='"$(PLUGIN_VERSION)"' -DMARKDOWN_PIDGIN

CC ?= gcc

ifeq ($(shell $(PKG_CONFIG) --exists purple 2>/dev/null && echo "true"),)
  TARGET = FAILNOPURPLE
  DEST =
else
  TARGET = libsignald.so
  DEST = $(DESTDIR)`$(PKG_CONFIG) --variable=plugindir purple`
  LOCALEDIR = $(DESTDIR)$(shell $(PKG_CONFIG) --variable=datadir purple)/locale
endif

CFLAGS += -DLOCALEDIR=\"$(LOCALEDIR)\"

PURPLE_COMPAT_FILES :=
PURPLE_C_FILES := libsignald.c $(C_FILES)

.PHONY:	all FAILNOPURPLE clean

LOCALES = $(patsubst %.po, %.mo, $(wildcard po/*.po))

all: $(TARGET)

libsignald.so: $(PURPLE_C_FILES) $(PURPLE_COMPAT_FILES)
	$(CC) -fPIC $(CFLAGS) $(CPPFLAGS) -shared -o $@ $^ $(LDFLAGS) `$(PKG_CONFIG) purple glib-2.0 json-glib-1.0 --libs --cflags`  $(INCLUDES) -Ipurple2compat -g -ggdb

FAILNOPURPLE:
	echo "You need libpurple development headers installed to be able to compile this plugin"

clean:
	rm -f $(TARGET)

gdb:
	gdb --args pidgin -c ~/.fake_purple -n -m

install: $(TARGET)
	mkdir -m $(DIR_PERM) -p $(DEST)
	install -m $(LIB_PERM) -p $(TARGET) $(DEST)
