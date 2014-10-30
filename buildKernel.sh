#!/bin/sh

# Copyright (C) 2011 Twisted Playground

# This script is designed by Twisted Playground for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

PROPER=`echo $1 | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`

HANDLE=LoungeKatt
KERNELSPEC=/Volumes/android/trltetmo-kernel
KERNELREPO=$DROPBOX_SERVER/TwistedServer/Playground/kernels
TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi-4.7/bin/arm-eabi-
MODULEOUT=$KERNELSPEC/buildimg/boot.img-ramdisk
KERNELHOST=public_html/trltetmo/kernel
GOOSERVER=upload.goo.im:$KERNELHOST
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`

LOCALZIP=$HANDLE"_StarKissed-NJ7-Note4.zip"
IMAGEFILE=boot.$PUNCHCARD.img
KERNELFILE=boot.$PUNCHCARD.tar
KERNELZIP=StarKissed-NJ7_$PUNCHCARD-Note4.zip

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
if [ -e $KERNELSPEC/trltetmoSKU/$LOCALZIP ];then
    rm -R $KERNELSPEC/trltetmoSKU/$LOCALZIP
fi

cp -R config/apq8084_sec_trlte_tmo_defconfig  arch/arm/configs/apq8084_sec_trlte_tmo_defconfig
cp -R config/apq8084_sec_defconfig  arch/arm/configs/apq8084_sec_defconfig

make -j$CPU_JOB_NUM -C $(pwd) clean
make -j$CPU_JOB_NUM -C $(pwd) VARIANT_DEFCONFIG=apq8084_sec_trlte_tmo_defconfig apq8084_sec_defconfig SELINUX_DEFCONFIG=selinux_defconfig CROSS_COMPILE=$TOOLCHAIN_PREFIX
make -j$CPU_JOB_NUM -C $(pwd) CROSS_COMPILE=$TOOLCHAIN_PREFIX

if [ -e arch/arm/boot/zImage ]; then

    MODULEOUT=$KERNELSPEC/buildimg/boot.img-ramdisk

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

    cp -R arch/arm/boot/zImage $KERNELSPEC/buildimg/zImage

    cd buildimg
    ./img.sh

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

    cp -r  output/boot.img $KERNELREPO/trltetmo/boot.img

#    if cat /etc/issue | grep Ubuntu; then
#        tar -H ustar -c output/boot.img > output/boot.tar
#    else
#        tar --format ustar -c output/boot.img > output/boot.tar
#    fi
    tar cvf output/boot.tar output/boot.img
    cp -r output/boot.tar $KERNELREPO/trltetmo/boot.tar
    cp -r output/boot.tar output/boot.tar.md5
    if cat /etc/issue | grep Ubuntu; then
        md5sum -t output/boot.tar.md5 >> output/boot.tar.md5
    else
        md5 -r output/boot.tar.md5 >> output/boot.tar.md5
    fi

    cp -r output/boot.tar.md5 $KERNELREPO/trltetmo/boot.tar.md5
    cp -R output/boot.img trltetmoSKU
    cd trltetmoSKU
    rm *.zip
    zip -r $LOCALZIP *
    cd ../
    cp -R $KERNELSPEC/trltetmoSKU/$LOCALZIP $KERNELREPO/$LOCALZIP

    echo "Publish Kernel?"
    read publish

    if [ $publish == "y" ]; then
        if [ -e $KERNELREPO/gooserver/ ]; then
            rm -R $KERNELREPO/gooserver/*.img
            rm -R $KERNELREPO/gooserver/*.tar
            rm -R $KERNELREPO/gooserver/*.md5
            rm -R $KERNELREPO/gooserver/*.zip
        fi
        cp -r  $KERNELREPO/trltetmo/boot.img $KERNELREPO/gooserver/$IMAGEFILE
        ssh upload.goo.im mv -f $KERNELHOST/*.img $KERNELHOST/archive/
        scp $KERNELREPO/gooserver/$IMAGEFILE $GOOSERVER
        cp -r $KERNELREPO/trltetmo/boot.tar $KERNELREPO/gooserver/$KERNELFILE
        ssh upload.goo.im mv -f $KERNELHOST/*.tar $KERNELHOST/archive/
        scp $KERNELREPO/gooserver/$KERNELFILE $GOOSERVER/
        cp -r $KERNELREPO/trltetmo/boot.tar.md5 $KERNELREPO/gooserver/$KERNELFILE.md5
        ssh upload.goo.im mv -f $KERNELHOST/*.md5 $KERNELHOST/archive/
        scp $KERNELREPO/gooserver/$KERNELFILE.md5 $GOOSERVER
        cp -r $KERNELREPO/$LOCALZIP $KERNELREPO/gooserver/$KERNELZIP
        ssh upload.goo.im mv -f $KERNELHOST/*.zip $KERNELHOST/archive/
        scp $KERNELREPO/gooserver/$KENRELZIP $GOOSERVER
    fi

fi

cd $KERNELSPEC
