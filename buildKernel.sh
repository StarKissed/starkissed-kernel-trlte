#!/bin/sh

# Copyright (C) 2011 Twisted Playground

# This script is designed by Twisted Playground for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

HANDLE=LoungeKatt
KERNELSPEC=/Volumes/android/starkissed-kernel-trlte
KERNELREPO=$DROPBOX_SERVER/TwistedServer/Playground/kernels
TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi-4.7/bin/arm-eabi-
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`

echo "1. T-Mo"
echo "2. AT&T"
echo "3. VZW"
echo "4. Spr"
echo "Please Choose: "
read profile

case $profile in
1)
TYPE=tmo
BUILD=NJ7
;;
2)
TYPE=att
BUILD=NA
;;
3)
TYPE=vzw
BUILD=NA
;;
4)
TYPE=spr
BUILD=NIE
;;
*)
exit 1
;;
esac

PROPER=`echo $TYPE | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`
MODULEOUT=$KERNELSPEC/build`echo $TYPE`/boot.img-ramdisk
KERNELHOST=public_html/trlte`echo $TYPE`/kernel
GOOSERVER=upload.goo.im:$KERNELHOST
IMAGEFILE=boot.$PUNCHCARD.img
KERNELFILE=boot.$PUNCHCARD.tar
LOCALZIP=$HANDLE"_StarKissed-trlte["`echo $TYPE`"."`echo $BUILD`"].zip"
KERNELZIP="StarKissed-"$PUNCHCARD"-trlte["`echo $TYPE`"."`echo $BUILD`"].zip"

CPU_JOB_NUM=8

if [ -e $KERNELSPEC/build`echo $TYPE`/boot.img ]; then
    rm -R $KERNELSPEC/build`echo $TYPE`/boot.img
fi
if [ -e $KERNELSPEC/build`echo $TYPE`/newramdisk.cpio.gz ]; then
    rm -R $KERNELSPEC/build`echo $TYPE`/newramdisk.cpio.gz
fi
if [ -e $KERNELSPEC/build`echo $TYPE`/zImage ]; then
    rm -R $KERNELSPEC/build`echo $TYPE`/zImage
fi
if [ -e arch/arm/boot/zImage ]; then
    rm -R arch/arm/boot/zImage
fi
if [ -e $KERNELSPEC/trlteSKU/$LOCALZIP ];then
    rm -R $KERNELSPEC/trlteSKU/$LOCALZIP
fi

cp -R config/trlte_`echo $TYPE`_defconfig arch/arm/configs/apq8084_sec_trlte_`echo $TYPE`_defconfig
cp -R config/apq8084_defconfig  arch/arm/configs/apq8084_sec_defconfig

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

    cp -R arch/arm/boot/zImage build`echo $TYPE`

    cd build`echo $TYPE`
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

    cp -r  output/boot.img $KERNELREPO/trlte`echo $TYPE`/boot.img

#    if cat /etc/issue | grep Ubuntu; then
#        tar -H ustar -c output/boot.img > output/boot.tar
#    else
#        tar --format ustar -c output/boot.img > output/boot.tar
#    fi
    tar cvf output/boot.tar output/boot.img
    cp -r output/boot.tar $KERNELREPO/trlte`echo $TYPE`/boot.tar
    cp -r output/boot.tar output/boot.tar.md5
    if cat /etc/issue | grep Ubuntu; then
        md5sum -t output/boot.tar.md5 >> output/boot.tar.md5
    else
        md5 -r output/boot.tar.md5 >> output/boot.tar.md5
    fi

    cp -r output/boot.tar.md5 $KERNELREPO/trlte`echo $TYPE`/boot.tar.md5
    cp -R output/boot.img trlteSKU
    cd trlteSKU
    rm *.zip
    zip -r $LOCALZIP *
    cd ../
    cp -R $KERNELSPEC/trlteSKU/$LOCALZIP $KERNELREPO/$LOCALZIP

    echo "Publish Kernel?"
    read publish

    if [ $publish == "y" || $publish == "m" ]; then
        if [ -e $KERNELREPO/gooserver/ ]; then
            rm -R $KERNELREPO/gooserver/*.img
            rm -R $KERNELREPO/gooserver/*.tar
            rm -R $KERNELREPO/gooserver/*.md5
            rm -R $KERNELREPO/gooserver/*.zip
        fi
        cp -r  $KERNELREPO/trlte`echo $TYPE`/boot.img $KERNELREPO/gooserver/$IMAGEFILE
if [ $publish == "y" ]; then
        ssh upload.goo.im mv -f $KERNELHOST/*.img $KERNELHOST/archive/
        scp $KERNELREPO/gooserver/$IMAGEFILE $GOOSERVER
fi
        cp -r $KERNELREPO/trlte`echo $TYPE`/boot.tar $KERNELREPO/gooserver/$KERNELFILE
if [ $publish == "y" ]; then
        ssh upload.goo.im mv -f $KERNELHOST/*.tar $KERNELHOST/archive/
        scp $KERNELREPO/gooserver/$KERNELFILE $GOOSERVER/
fi
        cp -r $KERNELREPO/trlte`echo $TYPE`/boot.tar.md5 $KERNELREPO/gooserver/$KERNELFILE.md5
if [ $publish == "y" ]; then
        ssh upload.goo.im mv -f $KERNELHOST/*.md5 $KERNELHOST/archive/
        scp $KERNELREPO/gooserver/$KERNELFILE.md5 $GOOSERVER
fi
        cp -r $KERNELREPO/$LOCALZIP $KERNELREPO/gooserver/`echo $KERNELZIP`
if [ $publish == "y" ]; then
        ssh upload.goo.im mv -f $KERNELHOST/*.zip $KERNELHOST/archive/
        scp `echo $KERNELREPO/gooserver/$KENRELZIP` $GOOSERVER
fi
    fi

fi

cd $KERNELSPEC
