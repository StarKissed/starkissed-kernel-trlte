mkdir $(pwd)/out
make -C $(pwd) O=$(pwd)/out VARIANT_DEFCONFIG=apq8084_sec_trlte_tmo_defconfig apq8084_sec_defconfig SELINUX_DEFCONFIG=selinux_defconfig
make -C $(pwd) O=$(pwd)/out
cp $(pwd)/out/arch/arm/boot/zImage $(pwd)/arch/arm/boot/zImage
