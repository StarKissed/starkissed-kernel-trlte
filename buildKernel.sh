#!/bin/sh

# Copyright (C) 2011 Twisted Playground
# Copyright (C) 2013 LoungeKatt

# This script is designed by Twisted Playground / LoungeKatt for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

HANDLE=LoungeKatt
KERNELSPEC=/Volumes/android/starkissed-kernel-trlte
KERNELREPO=$DROPBOX_SERVER/TwistedServer/Playground/kernels
TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi-4.7/bin/arm-eabi-
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`

buildKernel () {

PROPER=`echo $TYPE | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`
MODULEOUT=$KERNELSPEC/buildimg/boot.`echo $TYPE`-ramdisk
KERNELHOST=public_html/trlte`echo $TYPE`/kernel
GOOSERVER=upload.goo.im:$KERNELHOST
IMAGEFILE=boot-`echo $TYPE`.$PUNCHCARD.img
LOCALZIP=`echo $HANDLE"_StarKissed-trlte["$TYPE"."$BUILD"].zip"`
KERNELZIP=`echo "StarKissed-"$PUNCHCARD"-trlte["$TYPE"."$BUILD"].zip"`

CPU_JOB_NUM=8

if [ -e $KERNELSPEC/buildimg/boot.img ]; then
    rm -R $KERNELSPEC/buildimg/boot.img
fi
if [ -e $KERNELSPEC/buildimg/newramdisk.cpio.gz ]; then
    rm -R $KERNELSPEC/buildimg/newramdisk.cpio.gz
fi
if [ -e $KERNELSPEC/buildimg/zImage ]; then
    rm -R $KERNELSPEC/buildimg/zImage
fi
if [ -e arch/arm/boot/zImage ]; then
    rm -R arch/arm/boot/zImage
fi
if [ -e $KERNELSPEC/skrecovery/$LOCALZIP ];then
    rm -R $KERNELSPEC/skrecovery/$LOCALZIP
fi

cat config/trlte_`echo $TYPE`_defconfig config/trlte_gen_defconfig > arch/arm/configs/apq8084_sec_trlte_`echo $TYPE`_defconfig
cp -R config/trlte_sec_defconfig  arch/arm/configs/apq8084_sec_defconfig
if [ `echo $TYPE` != "sku" ]; then
    cp -R buildimg/boot.gen-ramdisk/* $MODULEOUT/
fi

make -j$CPU_JOB_NUM -C $(pwd) clean
make -j$CPU_JOB_NUM -C $(pwd) VARIANT_DEFCONFIG=apq8084_sec_trlte_`echo $TYPE`_defconfig apq8084_sec_defconfig SELINUX_DEFCONFIG=selinux_defconfig CROSS_COMPILE=$TOOLCHAIN_PREFIX
make -j$CPU_JOB_NUM -C $(pwd) CROSS_COMPILE=$TOOLCHAIN_PREFIX

if [ -e arch/arm/boot/zImage ]; then

    if [ `find . -name "*.ko" | grep -c ko` > 0 ]; then

        find . -name "*.ko" | xargs ${TOOLCHAIN_PREFIX}strip --strip-unneeded

        if [ ! -d $MODULEOUT ]; then
            mkdir $MODULEOUT
        fi
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

    cp -R arch/arm/boot/zImage buildimg

    cd buildimg
    ./img.sh `echo $TYPE`

    echo "building boot package"
    cp -R boot.img ../output
    cd ../

    if [ -e output/boot.tar ]; then
        rm -R output/boot.tar
    fi
    if [ -e output/boot.tar ]; then
        rm -R output/boot.tar.md5
    fi
    if [ -e output/boot.tar ]; then
        rm -R output/boot.tar.md5.gz
    fi

    cp -r  output/boot.img $KERNELREPO/trlte`echo $TYPE`/boot.img
    cp -r  output/boot.img starkissed/kernel/`echo $TYPE`/boot.img

    cp -R output/boot.img skrecovery
    cd skrecovery
    rm *.zip
    zip -r $LOCALZIP *
    cd ../
    cp -R $KERNELSPEC/skrecovery/$LOCALZIP $KERNELREPO/$LOCALZIP

    if [ $publish == "y" ] || [ $publish == "m" ] ; then
        if [ -e $KERNELREPO/gooserver/ ]; then
            rm -R $KERNELREPO/gooserver/*.{img,zip}
        fi
        cp -r  $KERNELREPO/trlte`echo $TYPE`/boot.img $KERNELREPO/gooserver/$IMAGEFILE
        cp -r $KERNELREPO/$LOCALZIP $KERNELREPO/gooserver/$KERNELZIP
    fi

    if [ $publish == "y" ]; then
        existing=`ssh upload.goo.im ls $KERNELHOST/*.{img,zip}`
        scp -r $KERNELREPO/gooserver/*.{img,zip} $GOOSERVER
        ssh upload.goo.im mv -t $KERNELHOST/archive/ $existing
    fi

fi

}

echo "1. T-Mobile"
echo "2. Sprint"
echo "3. Canadian"
echo "4. Verizon"
echo "5. US Cellular"
echo "6. AT&T"
echo "s. StarKissed"
echo "a. Circus"
echo "Please Choose: "
read profile
echo "Publish Kernel?"
read publish

case $profile in
1)
    TYPE=tmo
    BUILD=NJ7
    buildKernel
    exit
;;
2)
    TYPE=spr
    BUILD=NIE
    buildKernel
    exit
;;
3)
    TYPE=can
    BUILD=NJ3
    buildKernel
    exit
;;
4)
    TYPE=vzw
    BUILD=NI1
    buildKernel
    exit
;;
5)
    TYPE=usc
    BUILD=NA
    buildKernel
    exit
;;
6)
    TYPE=att
    BUILD=NIE
    buildKernel
    exit
;;
s)
    TYPE=sku
    BUILD=SKU
    buildKernel
    exit
;;
a)
    TYPE=tmo
    BUILD=NJ7
    buildKernel
    TYPE=spr
    BUILD=NIE
    buildKernel
    TYPE=can
    BUILD=NJ3
    buildKernel
    TYPE=vzw
    BUILD=NI1
    buildKernel
    TYPE=att
    BUILD=NIE
    buildKernel
    if [ $publish == "y" ] && [ 0 == 1 ] ; then
        if [ -e starkissed/StarKissed-Aroma-trlte_kernel.zip ];then
            rm -R starkissed/StarKissed-Aroma-trlte_kernel.zip
        fi
        cd starkissed
        zip -r StarKissed-Aroma-trlte_kernel.zip *
        cp -R StarKissed-Aroma-trlte_kernel.zip $KERNELREPO/StarKissed-Aroma-trlte_kernel.zip
    fi
    exit
;;
esac

cd $KERNELSPEC
