#!/bin/bash

BASE_F4K_VER="f4ktion_1.4.0"

case "$1" in
        eur_3g)
            VARIANT="eur_3g"
            VER=""
            ;;

        eur_lte)
            VARIANT="eur_lte"
            VER=""
            ;;

        *)
            VARIANT="eur_3g"
            VER=""
esac

BASE_F4K_VER=$BASE_F4K_VER-$VARIANT

if [ "$2" = "jb" ] ; then
	BASE_F4K_VER=$BASE_F4K_VER"-JB"
fi

F4K_VER=$BASE_F4K_VER$VER

export LOCALVERSION="-"`echo $F4K_VER`
export CROSS_COMPILE=/home/f4k/toolchains/arm-cortex_a15-linux-gnueabihf-linaro_4.9.1-2014.05/bin/arm-cortex_a15-linux-gnueabihf-
#export CROSS_COMPILE=/home/f4k/toolchains/arm-cortex_a15-linux-gnueabihf-linaro_4.7.4-2014.01/bin/arm-cortex_a15-linux-gnueabihf-
#export CROSS_COMPILE=/opt/toolchains/gcc-4.8/bin/arm-eabi-
#export CROSS_COMPILE=/home/f4k/CM11/prebuilts/gcc/linux-x86/arm/arm-eabi-4.7/bin/arm-eabi-
export ARCH=arm
export KBUILD_BUILD_USER=f4k
export KBUILD_BUILD_HOST="mint17x64"

echo 
echo "Making f4ktion_defconfig"

DATE_START=$(date +"%s")

make VARIANT_DEFCONFIG=msm8930_serrano_$VARIANT"_defconfig" SELINUX_DEFCONFIG=selinux_defconfig SELINUX_LOG_DEFCONFIG=selinux_log_defconfig f4ktion_defconfig

INIT_DIR=../ramdisks
MODULES_DIR=../filesdir/$VARIANT/lib/modules
KERNEL_DIR=`pwd`
OUTPUT_DIR=../output/$VARIANT
CWM_DIR=../filesdir/cwm
CWM_ANY_DIR=../filesdir/cwm_any

echo
if [ "$2" = "jb" ] ; then
        cd $INIT_DIR && git checkout jb-4.3
fi

cd $KERNEL_DIR

echo
echo "Removing old kernels files"
if [ -e $KERNEL_DIR/arch/arm/boot/zImage ]; then
	rm $CWM_DIR/boot.img
	rm $CWM_ANY_DIR/zImage
	rm arch/arm/boot/zImage
else
	echo "No kernels found"
fi

echo
echo "Removing old modules"
rm -R `find $KERNEL_DIR -name '*.ko'`
rm `echo $MODULES_DIR"/*"`
rm `echo $CWM_DIR/system/lib/modules/"*.ko"`

echo
echo "LOCALVERSION="$LOCALVERSION
echo "CROSS_COMPILE="$CROSS_COMPILE
echo "ARCH="$ARCH
echo "INIT_DIR="$INIT_DIR
echo "MODULES_DIR="$MODULES_DIR
echo "KERNEL_DIR="$KERNEL_DIR
echo "OUTPUT_DIR="$OUTPUT_DIR
echo "CWM_DIR="$CWM_DIR
echo "CWN_ANY_DIR="$CWM_ANY_DIR

make -j4 > /dev/null

echo
find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
find $MODULES_DIR -name '*.ko' -exec cp -v {} $CWM_DIR"/system/lib/modules/" \;

echo
if [ -e $KERNEL_DIR/arch/arm/boot/zImage ]; then
	cp arch/arm/boot/zImage $CWM_ANY_DIR
	cd $INIT_DIR
	./mkbootfs $VARIANT| gzip > $CWM_ANY_DIR/ramdisk.gz
	cd $CWM_ANY_DIR
	./mkbootimg --cmdline 'console = null androidboot.hardware=qcom user_debug=31 zcache androidboot.selinux=permissive' --kernel zImage --ramdisk ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output ../cwm/boot.img
	echo
	echo "Make zip package"
	cd ../cwm
	zip -r `echo $F4K_VER`.zip *
	mv  `echo $F4K_VER`.zip ../$OUTPUT_DIR
	cd ../$OUTPUT_DIR
	echo
	FILE_NAME=$F4K_VER.zip
	FILE_SIZE=$(stat -c%s "$FILE_NAME")
	echo "$F4K_VER.zip size is $FILE_SIZE bytes."
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;

echo
if [ "$2" = "jb" ] ; then
        cd ../$INIT_DIR && git checkout kk-4.4
fi

cd $KERNEL_DIR

DATE_END=$(date +"%s")
echo
DIFF=$(($DATE_END - $DATE_START))
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
