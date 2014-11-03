#!/bin/sh

# Copyright (C) 2011 Twisted Playground
# Copyright (C) 2013 LoungeKatt

# This script is designed by Twisted Playground / LoungeKatt for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

HANDLE=LoungeKatt
KERNELSPEC=/Volumes/android/starkissed-deported
KERNELREPO=$DROPBOX_SERVER/TwistedServer/Playground/kernels
TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi-4.7/bin/arm-eabi-
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`
LOCALZIP=$HANDLE"_StarKissed-trlte[Auto].zip"
KERNELZIP="StarKissed-"$PUNCHCARD"-trlte[Auto].zip"
AROMAZIP=$HANDLE"_StarKissed-trlte[Aroma].zip"
AROMAHOST="StarKissed-"$PUNCHCARD"-trlte[Aroma].zip"

buildKernel () {

PROPER=`echo $TYPE | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`
MODULEOUT=$KERNELSPEC/buildimg/boot.`echo $TYPE`-ramdisk
KERNELHOST=public_html/trltesku
GOOSERVER=upload.goo.im:$KERNELHOST
CARRIERIM=boot.`echo $TYPE`.img
IMAGEFILE=boot.`echo $TYPE`.$PUNCHCARD.img

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
cp -R buildimg/boot.gen-ramdisk/* $MODULEOUT/

if [ $publish == "y" ]; then
    starkissed Compiling
else
    starkissed Verifying
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
    cp -r boot.img $KERNELREPO/trltesku/$CARRIERIM
    cd ../

    if [ $publish == "y" ]; then
        starkissed Uploading
        if [ -e $KERNELREPO/gooserver/ ]; then
            rm -R $KERNELREPO/gooserver/*.img
        fi
        cp -r  $KERNELREPO/trltesku/$CARRIERIM $KERNELREPO/gooserver/$IMAGEFILE

        for i in $(megacmd list mega:/trltesku/ 2>&1 | awk '{print $1}' | grep -i $TYPE.img); do
            megacmd move $i mega:/trltesku/archive/$(basename $i)
        done
        megacmd put $KERNELREPO/gooserver/*.img mega:/trltesku/

        existing=`ssh upload.goo.im ls $KERNELHOST/*.$TYPE.img`
        scp -r $KERNELREPO/gooserver/*.img $GOOSERVER
        ssh upload.goo.im mv -t $KERNELHOST/archive/ $existing
    fi
    cp -r $KERNELREPO/trltesku/$CARRIERIM starkissed/kernel/`echo $TYPE`/boot.img
    cp -r $KERNELREPO/trltesku/$CARRIERIM skrecovery/kernel/`echo $TYPE`/boot.img
    starkissed Inactive

fi

}

buildAroma () {

    starkissed Packaging
    cd skrecovery
    rm *.zip
    zip -r $LOCALZIP *
    cd ../
    cp -R $KERNELSPEC/skrecovery/$LOCALZIP $KERNELREPO/$LOCALZIP

    if [ $publish == "y" ]; then
        starkissed Uploading
        if [ -e $KERNELREPO/gooserver/ ]; then
            rm -R $KERNELREPO/gooserver/*.zip
        fi
        cp -r $KERNELREPO/$LOCALZIP $KERNELREPO/gooserver/$KERNELZIP

        for i in $(megacmd list mega:/trltesku/ 2>&1 | awk '{print $1}' | grep -i .zip); do
            megacmd move $i mega:/trltesku/archive/$(basename $i)
        done
        megacmd put $KERNELREPO/gooserver/*.zip mega:/trltesku/

#        existing=`ssh upload.goo.im ls public_html/trltesku/kernel/*.zip`
#        scp -r $KERNELREPO/gooserver/*.zip $GOOSERVER
#        ssh upload.goo.im mv -t public_html/trltesku/kernel/archive/ $existing
    fi
    if [ -e starkissed/$AROMAZIP ];then
        rm -R starkissed/$AROMAZIP
    fi
    cd starkissed
    zip -r $AROMAZIP *
    cd ../
    cp -R $KERNELSPEC/starkissed/$AROMAZIP $KERNELREPO/$AROMAZIP
    starkissed Inactive

}

echo "1. StarKissed"
echo "2. Deported"
echo "3. Carrier"
echo "Please Choose: "
read profile

case $profile in
1)
    echo "Publish Image?"
    read publish
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
    TYPE=usc
    BUILD=NA
    buildKernel
    exit
;;
2)
    echo "Publish Package?"
    read publish
    buildAroma
    exit
;;
3)
    echo "Which Carrier?"
    read carrier
    echo "Publish Image?"
    read publish
    TYPE=$carrier
    buildKernel
    exit
;;
esac

cd $KERNELSPEC
