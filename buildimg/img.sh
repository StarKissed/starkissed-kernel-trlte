./dtbtool -o dt.img -s 4096 -p ../scripts/dtc/ ../arch/arm/boot/dts/
chmod a+r dt.img
./mkbootfs boot.img-ramdisk | gzip > newramdisk.cpio.gz
./mkbootimg --cmdline 'console=ttyHSL0,115200,n8 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3' --kernel zImage --ramdisk newramdisk.cpio.gz -o boot.img --base 0x00000000 --pagesize 4096 --ramdisk_offset 0x02000000 --tags_offset 0x01E00000 --dt dt.img
