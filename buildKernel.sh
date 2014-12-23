#!/bin/sh

# Copyright (C) 2011 Twisted Playground
# Copyright (C) 2013 LoungeKatt

# This script is designed by Twisted Playground / LoungeKatt for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

KERNELDIR=`pwd`
HANDLE=LoungeKatt
KERNELREPO=$DROPBOX_SERVER/TwistedServer/StarKissed/kernels
TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi-4.7/bin/arm-eabi-
#TOOLCHAIN_PREFIX=/Volumes/android/linaro-toolchain-eabi-4.8/bin/arm-none-linux-gnueabi-
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`

buildKernel () {

PROPER=`echo "$TYPE" | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`
RAMDISKOUT=buildimg/boot."$TYPE"-ramdisk
MODULEOUT=skrecovery/"$TYPE"/system
MEGASERVER=mega:/trltesku/
KERNELHOST=public_html/trltesku
GOOSERVER=upload.goo.im:$KERNELHOST
KERNELZIP="StarKissed-"$PUNCHCARD"-trlte"$TYPE".zip"

# CPU_JOB_NUM=`grep processor /proc/cpuinfo|wc -l`
CORES=`sysctl -a | grep machdep.cpu | grep core_count | awk '{print $2}'`
THREADS=`sysctl -a | grep machdep.cpu | grep thread_count | awk '{print $2}'`
CPU_JOB_NUM=$((($CORES * $THREADS) / 2))

if [ -e arch/arm/boot/zImage ]; then
    rm arch/arm/boot/zImage
fi

cat config/trlte_"$TYPE"_defconfig config/trlte_sku_defconfig > arch/arm/configs/apq8084_sec_trlte_"$TYPE"_defconfig
cp -R config/trlte_sec_defconfig  arch/arm/configs/apq8084_sec_defconfig

if [ $package == "y" ]; then
    starkissed Compiling
else
    starkissed Verifying
fi

make -j$CPU_JOB_NUM -C $(pwd) clean CROSS_COMPILE=$TOOLCHAIN_PREFIX
make -j$CPU_JOB_NUM -C $(pwd) VARIANT_DEFCONFIG=apq8084_sec_trlte_"$TYPE"_defconfig apq8084_sec_defconfig SELINUX_DEFCONFIG=selinux_defconfig CROSS_COMPILE=$TOOLCHAIN_PREFIX
make -j$CPU_JOB_NUM -C $(pwd) CROSS_COMPILE=$TOOLCHAIN_PREFIX

if [ -e arch/arm/boot/zImage ]; then

    if [ ! -d $MODULEOUT ]; then
        mkdir $MODULEOUT
    fi

    if [ `find . -name "*.ko" | grep -c ko` > 0 ]; then

        find . -name "*.ko" | xargs ${TOOLCHAIN_PREFIX}strip --strip-unneeded

        if [ ! -d $MODULEOUT/lib ]; then
            mkdir $MODULEOUT/lib
        fi
        if [ ! -d $MODULEOUT/lib/modules ]; then
            mkdir $MODULEOUT/lib/modules
        else
            rm -r $MODULEOUT/lib/modules
            mkdir $MODULEOUT/lib/modules
        fi

        for j in $(find . -name "*.ko"); do
            cp -R "${j}" $MODULEOUT/lib/modules
        done

    fi

    cp -r arch/arm/boot/zImage buildimg
    for k in $(find skrecovery -name "system"); do
        cp -R buildimg/system/etc "${k}"
    done

    cd buildimg
    ./img.sh "$TYPE"
    cd ../

    LOCALZIP=$HANDLE"_StarKissed-KK44-trlte"$TYPE".zip"
    cp -r buildimg/boot.img skrecovery/"$TYPE"/boot.img

    starkissed Packaging
    cd skrecovery/"$TYPE"
    if [ -e ~/.goo/ ]; then
        rm -r ~/.goo/StarKissed*"$TYPE"*.zip
    fi
    zip -r ~/.goo/$KERNELZIP *
    cd ../../

    if [ $package == "y" ]; then
        starkissed Uploading
#        for i in $(megacmd list $MEGASERVER 2>&1 | awk '{print $1}' | grep -i StarKissed*trlte"$TYPE".zip); do
#            megacmd move $i $MEGASERVER/archive/$(basename $i)
#        done
#        megacmd put ~/.goo/$KERNELZIP $MEGASERVER
        existing=`ssh upload.goo.im ls $KERNELHOST/StarKissed*trlte"$TYPE"*.zip`
        scp -r ~/.goo/$KERNELZIP $GOOSERVER
        ssh upload.goo.im rm $existing
    fi
    if [ "$TYPE" == "tmo" ]; then
        if [ -e $KERNELREPO/$LOCALZIP ]; then
            rm $KERNELREPO/$LOCALZIP
        fi
        cp -r ~/.goo/$KERNELZIP $KERNELREPO/$LOCALZIP
    fi
    starkissed Inactive
else
    starkissed Inactive
fi

}

rm -fR $(find . -name '*.orig'|xargs)

if [ "$1" == "trlte" ]; then
    profile=1
else
    echo
    echo "1. Trophaeum"
    echo "2. Versions"
    echo
    echo "Please Choose: "
    read profile
fi

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
    fi
    exit
;;
2)
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

cd $KERNELDIR
