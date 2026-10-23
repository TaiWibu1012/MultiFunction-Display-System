// SPDX-License-Identifier: GPL-2.0
/**
 * @file mfds_ctrl.c
 * @brief Multi-Function Display System (MFDS) Kiosk Hardware Platform Driver
 *
 * Provides hardware supervisory capabilities for a 24/7 headless Kiosk:
 *  - Physical Push Button with debouncing & threaded interrupt for screen toggle.
 *  - Kiosk Status LED showing operational / screen power state.
 *  - SoC Thermal Telemetry from BCM2711 thermal zone.
 *  - Userspace sysfs interface with sysfs_notify for real-time reactivity.
 *
 * Target: Raspberry Pi 4 Model B (Broadcom BCM2711) - Linux 6.6+ (aarch64)
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/gpio/consumer.h>
#include <linux/interrupt.h>
#include <linux/sysfs.h>
#include <linux/device.h>
#include <linux/mutex.h>
#include <linux/jiffies.h>
#include <linux/thermal.h>
#include <linux/kstrtox.h>

#define DRIVER_NAME "mfds_ctrl"
#define DEBOUNCE_DELAY_MS 250

struct mfds_kiosk_dev {
    struct device *dev;
    struct gpio_desc *btn_gpiod;
    struct gpio_desc *led_gpiod;
    int btn_irq;
    struct mutex lock;
    unsigned int button_count;
    bool screen_active;
    bool led_state;
    unsigned long last_irq_jiffies;
    struct thermal_zone_device *tz_dev;
};

/* Forward declaration */
static const struct attribute_group mfds_attr_group;

/* Top-half Interrupt Service Routine (Interrupt Context) */
static irqreturn_t mfds_btn_isr(int irq, void *dev_id)
{
    /* Return IRQ_WAKE_THREAD to safely handle work in process context */
    return IRQ_WAKE_THREAD;
}

/* Bottom-half Threaded Handler (Process Context) */
static irqreturn_t mfds_btn_thread_fn(int irq, void *dev_id)
{
    struct mfds_kiosk_dev *mdev = dev_id;
    unsigned long now = jiffies;

    mutex_lock(&mdev->lock);

    /* Software debouncing */
    if (time_before(now, mdev->last_irq_jiffies + msecs_to_jiffies(DEBOUNCE_DELAY_MS))) {
        mutex_unlock(&mdev->lock);
        return IRQ_HANDLED;
    }
    mdev->last_irq_jiffies = now;

    /* Register button event */
    mdev->button_count++;

    /* Toggle display screen state and sync LED */
    mdev->screen_active = !mdev->screen_active;
    mdev->led_state = mdev->screen_active;

    if (mdev->led_gpiod)
        gpiod_set_value_cansleep(mdev->led_gpiod, mdev->led_state ? 1 : 0);

    mutex_unlock(&mdev->lock);

    dev_info(mdev->dev, "Kiosk button pressed #%u -> Screen Power: %s\n",
             mdev->button_count, mdev->screen_active ? "ON" : "OFF");

    /* Notify userspace sysfs listeners (poll/select/epoll) */
    sysfs_notify(&mdev->dev->kobj, NULL, "screen_power");
    sysfs_notify(&mdev->dev->kobj, NULL, "button_count");

    return IRQ_HANDLED;
}

/* --- Sysfs Attributes --- */

static ssize_t screen_power_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct mfds_kiosk_dev *mdev = dev_get_drvdata(dev);
    bool active;

    mutex_lock(&mdev->lock);
    active = mdev->screen_active;
    mutex_unlock(&mdev->lock);

    return sysfs_emit(buf, "%d\n", active ? 1 : 0);
}

static ssize_t screen_power_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
    struct mfds_kiosk_dev *mdev = dev_get_drvdata(dev);
    bool new_state;
    int ret;

    ret = kstrtobool(buf, &new_state);
    if (ret)
        return ret;

    mutex_lock(&mdev->lock);
    mdev->screen_active = new_state;
    mdev->led_state = new_state;
    if (mdev->led_gpiod)
        gpiod_set_value_cansleep(mdev->led_gpiod, mdev->led_state ? 1 : 0);
    mutex_unlock(&mdev->lock);

    sysfs_notify(&dev->kobj, NULL, "screen_power");
    return count;
}
static DEVICE_ATTR_RW(screen_power);

static ssize_t button_count_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct mfds_kiosk_dev *mdev = dev_get_drvdata(dev);
    unsigned int count;

    mutex_lock(&mdev->lock);
    count = mdev->button_count;
    mutex_unlock(&mdev->lock);

    return sysfs_emit(buf, "%u\n", count);
}
static DEVICE_ATTR_RO(button_count);

static ssize_t led_state_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct mfds_kiosk_dev *mdev = dev_get_drvdata(dev);
    bool state;

    mutex_lock(&mdev->lock);
    state = mdev->led_state;
    mutex_unlock(&mdev->lock);

    return sysfs_emit(buf, "%d\n", state ? 1 : 0);
}

static ssize_t led_state_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
    struct mfds_kiosk_dev *mdev = dev_get_drvdata(dev);
    bool new_state;
    int ret;

    ret = kstrtobool(buf, &new_state);
    if (ret)
        return ret;

    mutex_lock(&mdev->lock);
    mdev->led_state = new_state;
    if (mdev->led_gpiod)
        gpiod_set_value_cansleep(mdev->led_gpiod, mdev->led_state ? 1 : 0);
    mutex_unlock(&mdev->lock);

    return count;
}
static DEVICE_ATTR_RW(led_state);

static ssize_t temp_mc_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct mfds_kiosk_dev *mdev = dev_get_drvdata(dev);
    int temp = 0;
    int ret;

    if (!mdev->tz_dev || IS_ERR(mdev->tz_dev))
        return sysfs_emit(buf, "-1\n");

    ret = thermal_zone_get_temp(mdev->tz_dev, &temp);
    if (ret)
        return ret;

    return sysfs_emit(buf, "%d\n", temp);
}
static DEVICE_ATTR_RO(temp_mc);

static ssize_t temp_c_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    struct mfds_kiosk_dev *mdev = dev_get_drvdata(dev);
    int temp = 0;
    int abs_temp;
    int ret;

    if (!mdev->tz_dev || IS_ERR(mdev->tz_dev))
        return sysfs_emit(buf, "N/A\n");

    ret = thermal_zone_get_temp(mdev->tz_dev, &temp);
    if (ret)
        return ret;

    abs_temp = abs(temp);
    return sysfs_emit(buf, "%s%d.%d C\n",
                      temp < 0 ? "-" : "",
                      abs_temp / 1000,
                      (abs_temp % 1000) / 100);
}
static DEVICE_ATTR_RO(temp_c);

/* Standardized SoC telemetry attribute per ipc-deploy-kiosk workflow */
static ssize_t soc_temp_show(struct device *dev, struct device_attribute *attr, char *buf)
{
    return temp_c_show(dev, attr, buf);
}
static DEVICE_ATTR_RO(soc_temp);

static ssize_t heartbeat_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count)
{
    /* Userspace heartbeat ping */
    dev_dbg(dev, "Heartbeat ping received from userspace kiosk\n");
    return count;
}
static DEVICE_ATTR_WO(heartbeat);

static struct attribute *mfds_attrs[] = {
    &dev_attr_screen_power.attr,
    &dev_attr_button_count.attr,
    &dev_attr_led_state.attr,
    &dev_attr_temp_mc.attr,
    &dev_attr_temp_c.attr,
    &dev_attr_soc_temp.attr,
    &dev_attr_heartbeat.attr,
    NULL,
};

static const struct attribute_group mfds_attr_group = {
    .attrs = mfds_attrs,
};

/* --- Platform Driver Lifecycle --- */

static int mfds_kiosk_probe(struct platform_device *pdev)
{
    struct device *dev = &pdev->dev;
    struct mfds_kiosk_dev *mdev;
    int ret;

    mdev = devm_kzalloc(dev, sizeof(*mdev), GFP_KERNEL);
    if (!mdev)
        return -ENOMEM;

    mdev->dev = dev;
    mutex_init(&mdev->lock);
    mdev->screen_active = true;
    mdev->led_state = true;
    platform_set_drvdata(pdev, mdev);

    /* Acquire optional GPIO descriptors from Device Tree */
    mdev->btn_gpiod = devm_gpiod_get_optional(dev, "button", GPIOD_IN);
    if (IS_ERR(mdev->btn_gpiod))
        return dev_err_probe(dev, PTR_ERR(mdev->btn_gpiod), "Failed to acquire button GPIO\n");

    mdev->led_gpiod = devm_gpiod_get_optional(dev, "led", GPIOD_OUT_HIGH);
    if (IS_ERR(mdev->led_gpiod))
        return dev_err_probe(dev, PTR_ERR(mdev->led_gpiod), "Failed to acquire LED GPIO\n");

    /* Configure threaded interrupt if button GPIO is present */
    if (mdev->btn_gpiod) {
        mdev->btn_irq = gpiod_to_irq(mdev->btn_gpiod);
        if (mdev->btn_irq > 0) {
            ret = devm_request_threaded_irq(dev, mdev->btn_irq,
                                           mfds_btn_isr,
                                           mfds_btn_thread_fn,
                                           IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
                                           "mfds_button", mdev);
            if (ret)
                dev_warn(dev, "Failed to register threaded IRQ %d (ret=%d)\n", mdev->btn_irq, ret);
        }
    }

    /* Locate BCM2711 SoC thermal zone */
    mdev->tz_dev = thermal_zone_get_zone_by_name("cpu-thermal");
    if (!mdev->tz_dev || IS_ERR(mdev->tz_dev))
        mdev->tz_dev = thermal_zone_get_zone_by_name("bcm2711_thermal");

    /* Register sysfs attribute group */
    ret = devm_device_add_group(dev, &mfds_attr_group);
    if (ret)
        return dev_err_probe(dev, ret, "Failed to register sysfs attribute group\n");

    dev_info(dev, "MFDS Kiosk Platform Controller initialized (IRQ=%d, LED=%s, Thermal=%s)\n",
             mdev->btn_irq,
             mdev->led_gpiod ? "GPIO" : "Virtual",
             (mdev->tz_dev && !IS_ERR(mdev->tz_dev)) ? "Active" : "Unavailable");

    return 0;
}

static int mfds_kiosk_remove(struct platform_device *pdev)
{
    struct mfds_kiosk_dev *mdev = platform_get_drvdata(pdev);

    if (mdev && mdev->led_gpiod)
        gpiod_set_value_cansleep(mdev->led_gpiod, 0);

    dev_info(&pdev->dev, "MFDS Kiosk Platform Controller unloaded\n");
    return 0;
}

static const struct of_device_id mfds_of_match[] = {
    { .compatible = "mfds,kiosk-ctrl" },
    { /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, mfds_of_match);

static struct platform_driver mfds_platform_driver = {
    .probe = mfds_kiosk_probe,
    .remove = mfds_kiosk_remove,
    .driver = {
        .name = DRIVER_NAME,
        .of_match_table = mfds_of_match,
    },
};

module_platform_driver(mfds_platform_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Tai Le <lephuctai10@gmail.com>");
MODULE_DESCRIPTION("Multi-Function Display System (MFDS) Kiosk Hardware Platform Driver");
MODULE_VERSION("1.0.0");
