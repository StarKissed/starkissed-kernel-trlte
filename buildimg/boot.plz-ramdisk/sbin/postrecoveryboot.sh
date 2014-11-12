#!/sbin/sh

rm /system/recovery-from-boot.p
umount /system
#echo -n -e '\x03\x00\x00\x00' | dd of=/dev/block/platform/msm_sdcc.1/by-name/param conv=notrunc 2>/dev/null

