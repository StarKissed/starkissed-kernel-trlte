/*
 *  Copyright (C)  2013 Jean-Pierre Rasquin <yank555.lu@gmail.com>
 *            (C)  2014 LoungeKatt <twistedumbrella@gmail.com>
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation, and
 * may be copied, distributed, and modified under those terms.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#ifndef _LINUX_CPUFREQ_HARDLIMIT_H
#define _LINUX_CPUFREQ_HARDLIMIT_H

#define CPUFREQ_HARDLIMIT_VERSION "v2.0a Note 4 Edition"

//#define CPUFREQ_HARDLIMIT_DEBUG // Add debugging prints in dmesg

/* Default frequencies for n910X */
#define CPUFREQ_HARDLIMIT_MAX_SCREEN_ON_STOCK	2803200
#define CPUFREQ_HARDLIMIT_MAX_SCREEN_OFF_STOCK	729600
#define CPUFREQ_HARDLIMIT_MIN_SCREEN_ON_STOCK	268000
#define CPUFREQ_HARDLIMIT_MIN_SCREEN_OFF_STOCK	268000
#define CPUFREQ_HARDLIMIT_WAKEUP_KICK_FREQ      1190400

#define CPUFREQ_HARDLIMIT_SCREEN_ON	 1		/* default, consider we boot with screen on */
#define CPUFREQ_HARDLIMIT_SCREEN_OFF 0

#define HARDLIMIT_USER_ENFORCED	1
#define HARDLIMIT_USER_DISABLED 0		/* default, hardlimit is disabled on boot */

/* Userspace access to scaling min/max */
#define CPUFREQ_HARDLIMIT_USERSPACE_DVFS_ALLOW	0
#define CPUFREQ_HARDLIMIT_USERSPACE_DVFS_IGNORE	1
#define CPUFREQ_HARDLIMIT_USERSPACE_DVFS_REFUSE	2

#define CPUFREQ_HARDLIMIT_WAKEUP_KICK_DELAY_MAX	10000	/* Don't allow for more than 10 seconds */

#define CPUFREQ_HARDLIMIT_WAKEUP_KICK_INACTIVE	0
#define CPUFREQ_HARDLIMIT_WAKEUP_KICK_ACTIVE	1

#define CPUFREQ_HARDLIMIT_WAKEUP_KICK_DISABLED	0

/* Export touchboost frequencies */
extern unsigned int touchboost_lo_freq;
extern unsigned int touchboost_hi_freq;

/* Sanitize cpufreq to hardlimits */
unsigned int check_cpufreq_hardlimit(unsigned int freq);

/* User enforce/disable */
unsigned int hardlimit_user_enforced_status(void);

/* Scaling min/max lock */
unsigned int userspace_dvfs_lock_status(void);

/* Hooks in cpufreq for scaling min./max. */
void update_scaling_limits(unsigned int freq_min, unsigned int freq_max);

#endif

