#!/bin/sh

# Copyright (C) 2011 Twisted Playground
# Copyright (C) 2013 LoungeKatt

# This script is designed by Twisted Playground / LoungeKatt for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

HANDLE=LoungeKatt
KERNELREPO=$DROPBOX_SERVER/TwistedServer/StarKissed/kernels
TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi-4.7/bin/arm-eabi-
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`
LOCALZIP=$HANDLE"_StarKissed-trlte[Auto].zip"
KERNELZIP="StarKissed-"$PUNCHCARD"-trlte[Auto].zip"
AROMAZIP=$HANDLE"_StarKissed-trlte[Aroma].zip"
AROMAHOST="StarKissed-"$PUNCHCARD"-trlte[Aroma].zip"
PHILZZIP=$HANDLE"_Philz_6.58.9-trlte[NA].zip"
RECOVERZIP="Philz_Touch_6.58.9-"$PUNCHCARD"-trlte[NA].zip"

buildKernel () {

PROPER=`echo "$TYPE" | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`
MODULEOUT=buildimg/boot."$TYPE"-ramdisk
MEGASERVER=mega:/trltesku/
KERNELHOST=public_html/trltesku
if [ "$TYPE" == "plz" ]; then
    IMAGETYPE=recovery
    CARRIERIM=recovery."$TYPE".img
    IMAGEFILE=recovery."$TYPE".$PUNCHCARD.img
else
    IMAGETYPE=boot
    CARRIERIM=boot."$TYPE".img
    IMAGEFILE=boot."$TYPE".$PUNCHCARD.img
fi
GOOSERVER=upload.goo.im:$KERNELHOST

# CPU_JOB_NUM=`grep processor /proc/cpuinfo|wc -l`
CORES=`sysctl -a | grep machdep.cpu | grep core_count | awk '{print $2}'`
THREADS=`sysctl -a | grep machdep.cpu | grep thread_count | awk '{print $2}'`
CPU_JOB_NUM=$((($CORES * $THREADS) / 2))

if [ -e buildimg/zImage ]; then
    rm -rf buildimg/zImage
fi
if [ -e arch/arm/boot/zImage ]; then
    rm -rf arch/arm/boot/zImage
fi
if [ -e skrecovery/$LOCALZIP ];then
    rm -rf skrecovery/$LOCALZIP
fi

if [ "$TYPE" == "plz" ]; then
    cp -r config/trlte_plz_defconfig arch/arm/configs/apq8084_sec_trlte_"$TYPE"_defconfig
else
    cat config/trlte_"$TYPE"_defconfig config/trlte_sku_defconfig > arch/arm/configs/apq8084_sec_trlte_"$TYPE"_defconfig
fi
cp -R config/trlte_sec_defconfig  arch/arm/configs/apq8084_sec_defconfig
if [ "$TYPE" != "plz" ]; then
    cp -R buildimg/boot.sku-ramdisk/* $MODULEOUT/
fi

if [ $publish == "y" ]; then
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
    ./img.sh "$TYPE"

    echo "building boot package"
    cp -r boot.img $KERNELREPO/trltesku/$CARRIERIM
    cd ../

    if [ $publish == "y" ]; then
        starkissed Uploading
        if [ -e ~/.goo/ ]; then
            rm -R ~/.goo/{boot,recovery}."$TYPE".*.img
        fi
        cp -r  $KERNELREPO/trltesku/$CARRIERIM ~/.goo/$IMAGEFILE

#       existing=`ssh upload.goo.im ls $KERNELHOST/"$IMAGETYPE"."$TYPE".*.img`
        scp -r ~/.goo/"$IMAGETYPE"."$TYPE".*.img $GOOSERVER
#       ssh upload.goo.im mv -t $KERNELHOST/archive/ $existing
    fi
    if [ "$TYPE" == "plz" ]; then
        cp -r $KERNELREPO/trltesku/$CARRIERIM plzrecovery/recovery.img
        starkissed Packaging
        cd plzrecovery
        rm *.zip
        zip -r $PHILZZIP *
        cd ../
        cp -R plzrecovery/$PHILZZIP $KERNELREPO/$PHILZZIP
        if [ $publish == "y" ]; then
            starkissed Uploading
            if [ -e ~/.goo/ ]; then
                rm -R ~/.goo/*.zip
            fi
            cp -r $KERNELREPO/$PHILZZIP ~/.goo/$RECOVERZIP

#           for i in $(megacmd list $MEGASERVER 2>&1 | awk '{print $1}' | grep -i .zip); do
#               megacmd move $i $MEGASERVER/archive/$(basename $i)
#           done
            megacmd put ~/.goo/*.zip $MEGASERVER
        fi
    else
        cp -r $KERNELREPO/trltesku/$CARRIERIM skrecovery/kernel/"$TYPE"/boot.img
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
rm *.zip
zip -r $LOCALZIP *
cd ../
cp -R skrecovery/$LOCALZIP $KERNELREPO/$LOCALZIP

if [ $publish == "y" ]; then
    starkissed Uploading
    if [ -e ~/.goo/ ]; then
        rm -R ~/.goo/*.zip
    fi
    cp -r $KERNELREPO/$LOCALZIP ~/.goo/$KERNELZIP

#   for i in $(megacmd list $MEGASERVER 2>&1 | awk '{print $1}' | grep -i .zip); do
#       megacmd move $i $MEGASERVER/archive/$(basename $i)
#   done
    megacmd put ~/.goo/*.zip $MEGASERVER
fi
starkissed Inactive

}

rm -fR $(find . -name '*.orig'|xargs)

echo
echo "1. Deported"
echo "2. Package"
echo "3. Carrier"
echo "4. Recovery"
echo "5. Versions"
echo
echo "Please Choose: "
read profile

case $profile in
1)
    echo "Publish Image?"
    read publish
    echo "Publish Package?"
    read package
    TYPE=tmo
    buildKernel
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
    if [ $package == "y" ]; then
        buildAroma
    fi
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
4)
    echo "Publish Image?"
    read publish
    TYPE=plz
    buildKernel
    exit
;;
5)
    echo "Bootloaders"
    echo
    echo "att - N/A"
    echo "can - NJ3"
    echo "spr - NIE"
    echo "tmo - NK4"
    echo "usc - N/A"
    echo "vzw - NI1"
    echo
    exit
;;
esac
