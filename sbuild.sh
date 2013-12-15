#!/bin/bash

BASE_F4K_VER="f4ktion_1.1.5"

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
#export CROSS_COMPILE=/opt/toolchains/gcc-linaro-arm-linux-gnueabihf-4.7-2013.04-20130415_linux/bin/arm-linux-gnueabihf-
export CROSS_COMPILE=/opt/toolchains/gcc-linaro-arm-linux-gnueabihf-4.8-2013.10_linux/bin/arm-linux-gnueabihf-
export ARCH=arm
export KBUILD_BUILD_USER=f4k
export KBUILD_BUILD_HOST="mint16x64"

echo 
echo "Making f4ktion_defconfig"

DATE_START=$(date +"%s")

make VARIANT_DEFCONFIG=msm8930_serrano_$VARIANT"_defconfig" SELINUX_DEFCONFIG=selinux_defconfig SELINUX_LOG_DEFCONFIG=selinux_log_defconfig f4ktion_defconfig

HOME_DIR=/home/f4k/kernels
INIT_DIR=$HOME_DIR/ramdisks/$VARIANT
MODULES_DIR=$HOME_DIR/filesdir/$VARIANT/lib/modules
KERNEL_DIR=`pwd`
OUTPUT_DIR=$HOME_DIR/output/
CWM_DIR=$HOME_DIR/filesdir/cwm/
CWM_ANY_DIR=$HOME_DIR/filesdir/cwm_any/

echo
echo "Remove old kernels"
rm $CWM_DIR/boot.img
rm $CWM_ANY_DIR/zImage
rm arch/arm/boot/zImage

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

echo
if [ "$2" = "jb" ] ; then
        cd $HOME_DIR/ramdisks/ && git checkout jb-4.3
fi

cd $KERNEL_DIR

make -j4 > /dev/null

echo
rm `echo $MODULES_DIR"/*"`
find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
find $MODULES_DIR -name '*.ko' -exec cp -v {} $CWM_DIR"system/lib/modules/" \;
cd $KERNEL_DIR

echo
if [ -e $KERNEL_DIR/arch/arm/boot/zImage ]; then
	cp arch/arm/boot/zImage $CWM_ANY_DIR/
	cd $CWM_ANY_DIR/
	echo "Make boot.img"
	./mkbootfs $INIT_DIR| gzip > $CWM_ANY_DIR/ramdisk.gz
	./mkbootimg --cmdline 'console = null androidboot.hardware=qcom user_debug=31 zcache' --kernel $CWM_ANY_DIR/zImage --ramdisk $CWM_ANY_DIR/ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output $CWM_DIR/boot.img

	cd $CWM_DIR
	zip -r `echo $F4K_VER`.zip *
	mv  `echo $F4K_VER`.zip $OUTPUT_DIR/$VARIANT
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;

echo
if [ "$2" = "jb" ] ; then
        cd $HOME_DIR/ramdisks/ && git checkout kk-4.4
fi

cd $KERNEL_DIR

DATE_END=$(date +"%s")
echo
DIFF=$(($DATE_END - $DATE_START))
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
