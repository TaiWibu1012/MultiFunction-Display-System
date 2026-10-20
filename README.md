# MULTI-FUNCTION DISPLAY SYSTEM — Embedded Linux & Qt 6

> **Authors & Core Contributors:**  
> - **Lê Phúc Tài** — System & Embedded Linux Engineer *(Custom Yocto OS, Out-of-tree Kernel Driver, Hardware Watchdog, DRM/KMS Kiosk Engine)*  
> - **Võ Thanh Dũng** — Application & UI Engineer *(Qt 6.8 QML Dashboard UI, Asynchronous Data Pipeline, HDMI Display Management)*  
>  
> **Target Hardware:** Raspberry Pi 4 Model B (Broadcom BCM2711, Quad-Core ARM Cortex-A72 @ 1.8 GHz, 64-bit ARMv8-A)  
> **Operating System:** Custom Embedded Linux (Yocto Project Poky 5.0 LTS Scarthgap, Linux Kernel 6.6.x LTS, 64-bit aarch64)  
> **Graphics Acceleration:** Native EGLFS KMS/DRM (`vc4-kms-v3d`) — Zero-overhead direct rendering (No X11 / Wayland)  

---

## 1. Project Overview

The **Multi-Function Display System (MFDS)** is a high-reliability, production-grade embedded edge appliance designed for dedicated information display boards, digital signage kiosks, and real-time dashboard systems. Built from the ground up, the system integrates a custom minimal Linux operating system (built with Yocto Project), kernel-level monitoring mechanisms, and a modern GPU-accelerated **Qt 6.8 (QML / Qt Quick)** graphical user interface.

Unlike traditional desktop distributions running heavy display servers (X11 / Wayland), MFDS boots straight into a hardware-accelerated **EGLFS KMS/DRM** graphics pipeline directly driving large HDMI monitors. This architecture significantly reduces RAM consumption, minimizes boot time, and guarantees full hardware resource dedication to the dashboard application.

```text
+-------------------------------------------------------------------------------+
|                     MULTI-FUNCTION DISPLAY SYSTEM (MFDS)                      |
+-------------------------------------------------------------------------------+
|  USER INTERFACE LAYER (Qt 6.8 QML / Qt Quick)                                 |
|  - Real-time News & Notices Card      - Schedule & Event Timetable Widget     |
|  - Dynamic Live Weather (REST API)    - System Telemetry & Status Indicator   |
+---------------------------------------+---------------------------------------+
|  APPLICATION RUNTIME                  |  DATA SYNCHRONIZATION PIPELINE        |
|  - Qt Quick Scene Graph (Hardware GL) |  - Non-blocking Network Fetcher       |
|  - EGLFS KMS/DRM Display Backend      - Local Cache & Fail-Safe Recovery      |
+---------------------------------------+---------------------------------------+
                    | (Direct DRM/KMS Framebuffer)
+-------------------------------------------------------------------------------+
|  LINUX SUBSYSTEM & SYSTEM INFRASTRUCTURE                                      |
|  - Systemd Headless Kiosk Service     - Hardware Watchdog (/dev/watchdog)     |
|  - Out-of-tree Kernel Telemetry Driver - Dropbear SSH & Network Management    |
+-------------------------------------------------------------------------------+
                    | (Broadcom BCM2711 SoC Drivers)
+-------------------------------------------------------------------------------+
|  HARDWARE LAYER (Raspberry Pi 4 Model B - 64-bit ARMv8-A)                     |
|  - 4x Cortex-A72 CPU @ 1.8 GHz        - VideoCore VI 3D GPU (V3D 4.2)         |
|  - Micro-HDMI Display Output          - Dual-Band Wi-Fi / Gigabit Ethernet    |
+-------------------------------------------------------------------------------+
```

---

## 2. Key Technical Highlights

* **Direct EGLFS KMS/DRM Rendering:** Eliminates compositing overhead by writing directly to the Linux Kernel Mode Setting (`KMS`) and Direct Rendering Manager (`DRM`) via OpenGL ES 2.0 / EGLFS, maximizing 60 FPS rendering on 1080p/4K HDMI displays.
* **Deterministic Minimal Linux OS:** Tailored with Yocto Project Poky 5.0 (Scarthgap LTS), stripped of unnecessary packages, desktop managers, and audio/printing daemons to maintain a sub-100 MB rootfs footprint.
* **System Hardening & Fail-Safe Watchdog:** Integrated with the Broadcom BCM2835/BCM2711 Hardware Watchdog (`/dev/watchdog`) to guarantee automatic reboot and self-healing in case of system lockup.
* **Kernel-Space Telemetry:** Custom out-of-tree character driver / sysfs interface exporting hardware metrics (SoC core temperature, memory pressure, display link state) to userspace applications.
* **Instant Kiosk Autostart:** Managed via custom `systemd` units starting the graphical runtime immediately upon boot without virtual terminals or mouse cursor interference.

---

## 3. Hardware Specifications & Interfaces

| Component | Specification | Function / Usage |
| :--- | :--- | :--- |
| **SoC** | Broadcom BCM2711 | Quad-Core Cortex-A72 (ARMv8-A) 64-bit @ 1.8 GHz |
| **GPU** | Broadcom VideoCore VI | OpenGL ES 3.1 / Vulkan 1.2 support via Mesa `vc4-kms-v3d` |
| **RAM** | 4 GB / | High-throughput system memory |
| **Display Output** | Micro-HDMI 0 (`HDMI-A-1`) | Native 1080p / 4K 60Hz HDMI video stream |
| **Network** | Gigabit Ethernet / 802.11ac Wi-Fi | REST API data synchronization, remote management |
| **Debug Console** | UART Serial (GPIO 14 TX, GPIO 15 RX) | 115200 baud, 8N1 serial kernel debugging |
| **Storage** | High-Speed MicroSD / eMMC | Bootable Yocto OS partitions (`boot` FAT32 + `rootfs` ext4) |

---

## 4. Custom Yocto Linux Distribution

The operating system image and cross-compilation toolchain are generated using **Yocto Project (Poky 5.0 LTS Scarthgap)**:

* **Machine Target:** `raspberrypi4-64` (64-bit aarch64 architecture)
* **Linux Kernel:** 6.6.x LTS (`linux-raspberrypi`)
* **Key Meta Layers:**
  - `meta`: OpenEmbedded-Core foundational metadata and cross-toolchain.
  - `meta-poky`: Poky reference distribution engine.
  - `meta-raspberrypi`: Official BSP layer providing BCM2711 firmware and DTBOs.
  - `meta-openembedded/meta-oe`: Extended system utilities (`htop`, `dropbear`).
  - `meta-qt6`: Qt 6.8 LTS framework integration (configured for `eglfs kms gbm gles2`).
* **Toolchain SDK:** AArch64 GCC 13.x / Glibc 2.39 toolchain featuring `kernel-devsrc` for out-of-tree module compilation and `populate_sdk_qt6_base` for native CMake toolchain integration.

---

## 5. Repository Structure

```text
MultiFunction-Display-System/
├── .gitignore                          # Standard C++, CMake, Qt6, Kernel & Yocto ignore filters
├── README.md                           # Master project documentation & architectural specifications
│
├── OS/                                 # Custom Yocto Linux OS recipes, configs & flash guides
├── devicetree/                         # Device Tree Source (.dts) & compiled overlays (.dtbo)
├── docs/                               # System architecture blueprints & technical documentation
├── include/                            # Shared C/C++ interface headers (Kernel <-> Userspace)
├── scripts/                            # Build automation, toolchain wrappers & deployment scripts
│
├── src/                                # Source code root
│   ├── app/                            # Qt 6.8 QML Dashboard application (Kiosk Mode)
│   │   └── components/                 # Reusable QML visual components (Cards, Banners, Widgets)
│   └── driver/                         # Out-of-tree Linux Kernel module (Telemetry & Hardware metrics)
│
└── systemd/                            # Systemd service configurations for Kiosk mode autostart
```

---

## 6. Development & Cross-Compilation Workflow

### 6.1. Environment Setup (Host Machine)
Ensure the Yocto AArch64 Cross-SDK is installed on the Linux host (e.g., at `/opt/poky/5.0.19-pi4-64`):

```bash
# Source the cross-compilation environment variables
source /opt/poky/5.0.19-pi4-64/environment-setup-cortexa72-poky-linux
```

### 6.2. Building the Qt 6.8 Dashboard Application
The application utilizes CMake with the SDK-provided Qt toolchain file:

```bash
cd src/app
qt-cmake -B build -S . -G Ninja
cmake --build build
```

### 6.3. Building the Out-of-Tree Kernel Driver
Ensure `kernel-devsrc` is populated within the target sysroot:

```bash
cd src/driver
make ARCH=arm64 CROSS_COMPILE=aarch64-poky-linux- KDIR=/opt/poky/5.0.19-pi4-64/sysroots/cortexa72-poky-linux/usr/src/kernel
```

---

## 7. License & Contributions

Distributed under the **MIT License**. Contributions, issue reports, and architecture reviews are welcome.
