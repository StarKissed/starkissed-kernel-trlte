#!/bin/sh

# Copyright (C) 2011 Twisted Playground
# Copyright (C) 2013 LoungeKatt

# This script is designed by Twisted Playground / LoungeKatt for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

HANDLE=LoungeKatt
KERNELREPO=$DROPBOX_SERVER/TwistedServer/StarKissed/kernels
TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi-4.7/bin/arm-eabi-
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`
KERNELZIP="StarKissed-"$PUNCHCARD"-trlte[Auto].zip"
RECOVERZIP="Philz_Touch_6.58.9-"$PUNCHCARD"-trlte[NA].zip"

buildKernel () {

PROPER=`echo "$TYPE" | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`
RAMDISKOUT=buildimg/boot."$TYPE"-ramdisk
MEGASERVER=mega:/trltesku/
KERNELHOST=public_html/trltesku
GOOSERVER=upload.goo.im:$KERNELHOST

# CPU_JOB_NUM=`grep processor /proc/cpuinfo|wc -l`
CORES=`sysctl -a | grep machdep.cpu | grep core_count | awk '{print $2}'`
THREADS=`sysctl -a | grep machdep.cpu | grep thread_count | awk '{print $2}'`
CPU_JOB_NUM=$((($CORES * $THREADS) / 2))

if [ -e arch/arm/boot/zImage ]; then
    rm -rf arch/arm/boot/zImage
fi

if [ "$TYPE" == "plz" ]; then
    cp -r config/trlte_plz_defconfig arch/arm/configs/apq8084_sec_trlte_"$TYPE"_defconfig
else
    cat config/trlte_"$TYPE"_defconfig config/trlte_sku_defconfig > arch/arm/configs/apq8084_sec_trlte_"$TYPE"_defconfig
fi
cp -R config/trlte_sec_defconfig  arch/arm/configs/apq8084_sec_defconfig
if [ "$TYPE" != "plz" ]; then
    cp -R buildimg/boot.sku-ramdisk/* $RAMDISKOUT/
fi

if [ $package == "y" ]; then
    starkissed Compiling
else
    starkissed Verifying
fi

make -j$CPU_JOB_NUM -C $(pwd) clean CROSS_COMPILE=$TOOLCHAIN_PREFIX
make -j$CPU_JOB_NUM -C $(pwd) VARIANT_DEFCONFIG=apq8084_sec_trlte_"$TYPE"_defconfig apq8084_sec_defconfig SELINUX_DEFCONFIG=selinux_defconfig CROSS_COMPILE=$TOOLCHAIN_PREFIX
make -j$CPU_JOB_NUM -C $(pwd) CROSS_COMPILE=$TOOLCHAIN_PREFIX

if [ -e arch/arm/boot/zImage ]; then

    if [ `find . -name "*.ko" | grep -c ko` > 0 ]; then

        find . -name "*.ko" | xargs ${TOOLCHAIN_PREFIX}strip --strip-unneeded

        if [ ! -d $RAMDISKOUT ]; then
            mkdir $RAMDISKOUT
        fi
        if [ ! -d $RAMDISKOUT/lib ]; then
            mkdir $RAMDISKOUT/lib
        fi
        if [ ! -d $RAMDISKOUT/lib/modules ]; then
            mkdir $RAMDISKOUT/lib/modules
        else
            rm -r $RAMDISKOUT/lib/modules
            mkdir $RAMDISKOUT/lib/modules
        fi

        for j in $(find . -name "*.ko"); do
            cp -r "${j}" $RAMDISKOUT/lib/modules
        done

    fi

    cp -R arch/arm/boot/zImage buildimg

    cd buildimg
    ./img.sh "$TYPE"
    cd ../

    if [ "$TYPE" == "plz" ]; then
        if [ $package != "y" ]; then
            if [ -e $KERNELREPO/images/trlte-recovery.img ]; then
                rm -r $KERNELREPO/images/trlte-recovery.img
            fi
            cp -r buildimg/boot.img $KERNELREPO/images/trlte-recovery.img
        fi
        cp -r buildimg/boot.img plzrecovery/recovery.img
        starkissed Packaging
        cd plzrecovery
        if [ -e ~/.goo/ ]; then
            rm -r ~/.goo/Philz_Touch*.zip
        fi
        zip -r ~/.goo/$RECOVERZIP *
        cd ../
        if [ $package == "y" ]; then
            starkissed Uploading

            for i in $(megacmd list $MEGASERVER 2>&1 | awk '{print $1}' | grep -i Philz_Touch); do
                megacmd move $i $MEGASERVER/archive/$(basename $i)
            done
            megacmd put ~/.goo/$RECOVERZIP $MEGASERVER
            existing=`ssh upload.goo.im ls $KERNELHOST/Philz_Touch*.zip`
            scp -r ~/.goo/$RECOVERZIP $GOOSERVER
            ssh upload.goo.im rm $existing
        fi
    else
        if [ $package != "y" ]; then
            if [ -e $KERNELREPO/images/trlte-deported.img ]; then
                rm -r $KERNELREPO/images/trlte-deported.img
            fi
            cp -r buildimg/boot.img $KERNELREPO/images/trlte-deported.img
        fi
        cp -r buildimg/boot.img skrecovery/kernel/"$TYPE"/boot.img
    fi
    starkissed Inactive
else
    starkissed Inactive
fi

}

buildAroma () {

MEGASERVER=mega:/trltesku/
KERNELHOST=public_html/trltesku
GOOSERVER=upload.goo.im:$KERNELHOST

starkissed Packaging
cd skrecovery
if [ -e ~/.goo/ ]; then
    rm -R ~/.goo/Deported*.zip
fi
zip -r ~/.goo/$KERNELZIP *
cd ../

if [ $package == "y" ]; then
    starkissed Uploading

    for i in $(megacmd list $MEGASERVER 2>&1 | awk '{print $1}' | grep -i Deported); do
        megacmd move $i $MEGASERVER/archive/$(basename $i)
    done
    megacmd put ~/.goo/$KERNELZIP $MEGASERVER
    existing=`ssh upload.goo.im ls $KERNELHOST/Deported*.zip`
    scp -r ~/.goo/$KERNELZIP $GOOSERVER
    ssh upload.goo.im rm $existing
fi
starkissed Inactive

}

rm -fR $(find . -name '*.orig'|xargs)

echo
echo "1. Deported"
echo "2. Package"
echo "3. Recovery"
echo "4. Versions"
echo
echo "Please Choose: "
read profile

case $profile in
1)
    echo "Publish Package?"
    read package
    TYPE=tmo
    buildKernel
    if [ $package == "y" ]; then
        TYPE=spr
        buildKernel
        TYPE=can
        buildKernel
        TYPE=usc
        buildKernel
        TYPE=vzw
        buildKernel
        if [ 0 = 1 ]; then
            TYPE=att
            buildKernel
        fi
        buildAroma
    fi
    exit
;;
2)
    echo "Publish Package?"
    read package
    buildAroma
    exit
;;
3)
    echo "Publish Package?"
    read package
    TYPE=plz
    buildKernel
    exit
;;
4)
    starkissed Verifying
    echo "Bootloaders"
    echo
    echo "att - N/A"
    echo "can - NJ3"
    echo "spr - NIE"
    echo "tmo - NK4"
    echo "usc - N/A"
    echo "vzw - NI1"
    echo
    starkissed Inactive
    exit
;;
esac
