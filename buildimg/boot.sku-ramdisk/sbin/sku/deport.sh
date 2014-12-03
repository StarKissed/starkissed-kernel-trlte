#!/system/bin/sh

/sbin/sku/busybox mount -o rw,remount /
/sbin/sku/busybox mount -o rw,remount /system
for i in $(ls /lib/modules 2>&1 | awk '{print $1}' | grep -i .ko); do
    if [ -e /system/lib/modules/$i ]; then
        rm /system/lib/modules/$i
    fi
    ln -s /lib/modules/$i /system/lib/$i
done
/sbin/sku/busybox mount -o ro,remount /system
/sbin/sku/busybox mount -o ro,remount /