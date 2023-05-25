export LC_ALL=C
SHELL:=/bin/bash

ifeq ($(FFMPEG_PARAM),)
  ifneq ($(wildcard ../Makefile.param),)
    include ../Makefile.param
  else
    include build/Makefile.param
  endif
endif

ifeq ($(filter $(RK_APP_ARCH_TYPE), arm arm64),)
$(error Unwanted ARCH=$(RK_APP_ARCH_TYPE))
endif

ifeq ($(RK_APP_ARCH_TYPE),arm)
PKG_USE_THUMB2 			?= YES
endif

include build/config.mk

CURRENT_DIR             := $(shell pwd)

PKG_BIN                 := out
PKG_BIN_INSTALL_DIR     := install_out
PKG_BIN_INSTALL         := $(PKG_BIN_INSTALL_DIR)/root

ifeq ($(RK_APP_ARCH_TYPE), arm64)
PKG_CFG_FLAGS           += --arch=aarch64
endif

ifeq ($(RK_APP_ARCH_TYPE), arm)
PKG_CFG_FLAGS           += --arch=arm --enable-neon
endif

ifeq ($(PKG_USE_THUMB2),YES)
PKG_CFG_FLAGS           += --enable-thumb
endif

#---------------------------------------
# Cross-compile setup:
CROSS_COMPILE           := $(RK_APP_CROSS)-
PKG_CFG_FLAGS           += --cc=$(CROSS_COMPILE)gcc
PKG_CFG_FLAGS           += --cxx=$(CROSS_COMPILE)g++
ifeq ($(RK_APP_LIB_TYPE),uclibc)
PKG_CFG_FLAGS           += --ld="$(CROSS_COMPILE)ld -lc"
else
PKG_CFG_FLAGS           += --ld=$(CROSS_COMPILE)ld
endif
PKG_CFG_FLAGS           += --ar=$(CROSS_COMPILE)ar
PKG_CFG_FLAGS           += --strip=$(CROSS_COMPILE)strip
PKG_CFG_FLAGS           += --ranlib=$(CROSS_COMPILE)ranlib
PKG_CROSS_CFLAGS        += $(RK_APP_OPTS)
PKG_CROSS_CFLAGS        += $(RK_APP_CROSS_CFLAGS)
PKG_CROSS_LDFLAGS       += $(RK_APP_CROSS_LDFLAGS)

#---------------------------------------
# Standard options:
PKG_CFG_FLAGS           += --prefix=$(PKG_BIN_INSTALL)
PKG_CFG_FLAGS           += --enable-cross-compile
PKG_CFG_FLAGS           += --target-os=linux
PKG_CFG_FLAGS           += --enable-pic
PKG_CFG_FLAGS           += --enable-optimizations --enable-debug --enable-small
PKG_CFG_FLAGS           += $(COMMON_FF_CFG_FLAGS)

all: ffmpeg
	@echo "build $@ done"

.PHONY: config build install
config: LOCAL_PKG_CFG_FLAGS=$(strip $(PKG_CFG_FLAGS))
config: LOCAL_PKG_CROSS_CFLAGS=$(strip $(PKG_CROSS_CFLAGS))
config: LOCAL_PKG_CROSS_LDFLAGS=$(strip $(PKG_CROSS_LDFLAGS))
config:
	@echo "-------------------------"
	@echo "[*] configure FFMpeg"
	@echo "-------------------------"
	@test -f config.h || ./configure $(LOCAL_PKG_CFG_FLAGS) --extra-cflags="$(LOCAL_PKG_CROSS_CFLAGS)" --extra-ldflags="$(LOCAL_PKG_CROSS_LDFLAGS)"

build:
	@make -j$(RK_APP_JOBS)

install:
	@make install

.PHONY: ffmpeg
ffmpeg: config build install
	@echo "-------------------------"
	@echo "[*] BEBEBE"
	@echo "-------------------------"

clean: distclean

distclean:
	@make distclean

info:
