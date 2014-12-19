/*
 *  linux/drivers/cpufreq/cpufreq_raccoon_city.c
 *
 *  Copyright (C) 2002 - 2003 Dominik Brodowski <linux@brodo.de>
 *            (C) 2014 LoungeKatt <twistedumbrella@gmail.com>
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */

#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

#include <linux/cpufreq.h>
#include <linux/init.h>
#include <linux/module.h>
#ifdef CONFIG_POWERSUSPEND
#include <linux/powersuspend.h>
#endif

#define DEFAULT_GOVERNOR_FREQ_OFF   1190400
unsigned int max_governor_freq;
unsigned int max_freq_screen_off = DEFAULT_GOVERNOR_FREQ_OFF;

static int cpufreq_governor_raccoon_city(struct cpufreq_policy *policy,
					unsigned int event)
{
	switch (event) {
	case CPUFREQ_GOV_START:
	case CPUFREQ_GOV_LIMITS:
		pr_debug("setting to %u kHz because of event %u\n",
						max_governor_freq, event);
		__cpufreq_driver_target(policy, max_governor_freq,
						CPUFREQ_RELATION_H);
		break;
	default:
		break;
	}
	return 0;
}

#ifdef CONFIG_POWERSUSPEND
static ssize_t max_freq_screen_off_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    return sprintf(buf, "%d\n", max_freq_screen_off);
}

static ssize_t max_freq_screen_off_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
    unsigned int new_max_freq_screen_off;
    
    if (!sscanf(buf, "%du", &new_max_freq_screen_off))
    return -EINVAL;
    
    if (new_max_freq_screen_off == max_freq_screen_off)
    return count;
    
    max_freq_screen_off = new_max_freq_screen_off;
    return count;
}

static struct kobj_attribute max_freq_screen_off_attr = __ATTR(max_freq_screen_off, 0666, max_freq_screen_off_show, max_freq_screen_off_store);
#endif

static struct attribute *raccoon_city_attributes[] = {
#ifdef CONFIG_POWERSUSPEND
    &max_freq_screen_off_attr.attr,
#endif
    NULL,
};

static struct attribute_group raccoon_city_attr_group = {
    .attrs = raccoon_city_attributes,
    .name = "raccoon_city",
};

#ifdef CONFIG_POWERSUSPEND
static void cpufreq_raccoon_city_power_suspend(struct power_suspend *h)
{
    mutex_lock(&gov_lock);
    if (max_governor_freq != max_freq_screen_off) {
        max_governor_freq = max_freq_screen_off;
    }
    mutex_unlock(&gov_lock);
}

static void cpufreq_raccoon_city_power_resume(struct power_suspend *h)
{
    mutex_lock(&gov_lock);
    struct cpufreq_policy *policy = cpufreq_cpu_get(0);
    max_governor_freq = policy->max;
    mutex_unlock(&gov_lock);
}

static struct power_suspend cpufreq_raccoon_city_power_suspend_info = {
    .suspend = cpufreq_raccoon_city_power_suspend,
    .resume = cpufreq_raccoon_city_power_resume,
};
#endif

#ifdef CONFIG_CPU_FREQ_DEFAULT_GOV_RACCOON_CITY
static
#endif
struct cpufreq_governor cpufreq_gov_raccoon_city = {
	.name		= "raccoon_city",
	.governor	= cpufreq_governor_raccoon_city,
	.owner		= THIS_MODULE,
};

static int __init cpufreq_gov_raccoon_city_init(void)
{
    struct cpufreq_policy *policy = cpufreq_cpu_get(0);
    max_governor_freq = policy->max;
#ifdef CONFIG_POWERSUSPEND
    register_power_suspend(&cpufreq_raccoon_city_power_suspend_info);
#endif
	return cpufreq_register_governor(&cpufreq_gov_raccoon_city);
}

static void __exit cpufreq_gov_raccoon_city_exit(void)
{
	cpufreq_unregister_governor(&cpufreq_gov_raccoon_city);
}

MODULE_AUTHOR("LoungeKatt <twistedumbrella@gmail.com>");
MODULE_DESCRIPTION("CPUfreq policy governor 'raccoon_city'");
MODULE_LICENSE("GPL");

#ifdef CONFIG_CPU_FREQ_DEFAULT_GOV_RACCOON_CITY
fs_initcall(cpufreq_gov_raccoon_city_init);
#else
module_init(cpufreq_gov_raccoon_city_init);
#endif
module_exit(cpufreq_gov_raccoon_city_exit);
