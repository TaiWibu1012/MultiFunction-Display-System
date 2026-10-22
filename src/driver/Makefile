# ==============================================================================
# Makefile for MFDS Kiosk Platform Driver (src/driver/Makefile)
# Target: Raspberry Pi 4 Model B (Linux 6.6.63-v8 aarch64)
# ==============================================================================

obj-m += mfds_ctrl.o

# Auto-detect Kernel Build Directory (Yocto Tree / SDK / Native)
YOCTO_KDIR := /home/tai/yocto-build/build_pi4_64/tmp/work/raspberrypi4_64-poky-linux/linux-raspberrypi/6.6.63+git/linux-raspberrypi4_64-standard-build
SDK_KDIR   := /opt/poky/5.0.19-pi4-64/sysroots/cortexa72-poky-linux/usr/src/kernel

ifneq ($(wildcard $(YOCTO_KDIR)),)
    KDIR ?= $(YOCTO_KDIR)
else ifneq ($(wildcard $(SDK_KDIR)),)
    KDIR ?= $(SDK_KDIR)
else
    KDIR ?= /lib/modules/$(shell uname -r)/build
endif

PWD    := $(shell pwd)
DTC    ?= /opt/poky/5.0.19-pi4-64/sysroots/x86_64-pokysdk-linux/usr/bin/dtc
DT_SRC := ../../devicetree/mfds-kiosk-overlay.dts
DT_OUT := ../../devicetree/mfds-kiosk-overlay.dtbo

.PHONY: all modules dtbo clean

all: modules dtbo
	@echo "=================================================="
	@echo "  MFDS KERNEL DRIVER & DTBO BUILD COMPLETED"
	@echo "=================================================="

modules:
	@echo "--- [1/2] Compiling Kernel Platform Driver (mfds_ctrl.ko) ---"
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=arm64 modules

dtbo:
	@echo "--- [2/2] Compiling Device Tree Overlay (mfds-kiosk-overlay.dtbo) ---"
	@if [ -x "$(DTC)" ]; then \
		$(DTC) -@ -I dts -O dtb -o $(DT_OUT) $(DT_SRC) && echo "[SUCCESS] Overlay created: $(DT_OUT)"; \
	else \
		dtc -@ -I dts -O dtb -o $(DT_OUT) $(DT_SRC) || echo "[WARN] dtc not found, skipping DTBO compilation"; \
	fi

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	rm -f $(DT_OUT)
