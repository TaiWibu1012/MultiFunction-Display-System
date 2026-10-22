#ifndef MFDS_CTRL_H
#define MFDS_CTRL_H

/**
 * @file mfds_ctrl.h
 * @brief Common Hardware and Sysfs Definitions for MFDS Kiosk Controller
 * Target: Raspberry Pi 4 Model B (Broadcom BCM2711)
 */

/* Hardware GPIO Pin Assignments (Raspberry Pi 4 Header) */
#define MFDS_GPIO_BUTTON_PIN        17  /* Pin 11 (GPIO 17, Active Low with internal Pull-Up) */
#define MFDS_GPIO_LED_PIN           27  /* Pin 13 (GPIO 27, Active High Status LED) */

/* Device Tree Compatible & Platform Driver Names */
#define MFDS_DT_COMPATIBLE          "mfds,kiosk-ctrl"
#define MFDS_PLATFORM_DEVICE_NAME   "mfds_ctrl"

/* Sysfs Attribute Paths */
#define MFDS_SYSFS_PATH             "/sys/devices/platform/mfds_ctrl"
#define MFDS_SYSFS_SCREEN_POWER     MFDS_SYSFS_PATH "/screen_power"
#define MFDS_SYSFS_BUTTON_COUNT     MFDS_SYSFS_PATH "/button_count"
#define MFDS_SYSFS_LED_STATE        MFDS_SYSFS_PATH "/led_state"
#define MFDS_SYSFS_TEMP_MC          MFDS_SYSFS_PATH "/temp_mc"
#define MFDS_SYSFS_TEMP_C           MFDS_SYSFS_PATH "/temp_c"
#define MFDS_SYSFS_HEARTBEAT        MFDS_SYSFS_PATH "/heartbeat"

#endif /* MFDS_CTRL_H */
