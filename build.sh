#!/bin/bash
rm -rf build

if [ -d ffmpeg ]; then
  echo "OK"
else
  tar -zxvf ffmpeg-2.0.tar.gz
  mv ffmpeg-2.0 ffmpeg
fi



DEST=`pwd`/build/ffmpeg && rm -rf $DEST
SOURCE=`pwd`/ffmpeg

PREBUILT=$NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86_64
SYSROOT=$NDK/platforms/android-18/arch-arm

export PATH=$PREBUILT/bin:$PATH
export CC=$PREBUILT/bin/arm-linux-androideabi-gcc
export LD=$PREBUILT/bin/arm-linux-androideabi-ld
export AR=$PREBUILT/bin/arm-linux-androideabi-ar
export RANLIB=$PREBUILT/bin/arm-linux-androideabi-ranlib
export STRIP=$PREBUILT/bin/arm-linux-androideabi-strip

CFLAGS="-O3 -Wall -mthumb -pipe -fpic -fasm \
  -finline-limit=300 -ffast-math \
  -fmodulo-sched -fmodulo-sched-allow-regmoves \
  -Wno-psabi -Wa,--noexecstack \
  -D__ARM_ARCH_5__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5TE__ \
  -DANDROID -DNDEBUG"

FFMPEG_FLAGS="--target-os=linux \
  --sysroot=$SYSROOT \
  --cc=$CC \
  --arch=arm \
  --enable-cross-compile \
  --cross-prefix=arm-linux-androideabi- \
  --enable-shared \
  --enable-static \
  --disable-symver \
  --disable-doc \
  --disable-ffplay \
  --disable-ffmpeg \
  --disable-ffprobe \
  --disable-ffserver \
  --disable-avdevice \
  --disable-avfilter \
  --disable-encoders \
  --disable-muxers \
  --disable-filters \
  --disable-devices \
  --disable-network \
  --disable-everything\
  --enable-decoder=h264 \
  --enable-decoder=mjpeg \
  --enable-decoder=mpeg4 \
  --enable-swscale \
  --disable-asm \
  --enable-version3"


for version in neon armv7 vfp armv6; do
#for version in neon; do
  cd $SOURCE

  case $version in
    neon)
      EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mvectorize-with-neon-quad"
      EXTRA_LDFLAGS=""
      ;;
    armv7)
      EXTRA_CFLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp"
      EXTRA_LDFLAGS=""
      ;;
    vfp)
      EXTRA_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=softfp"
      EXTRA_LDFLAGS=""
      ;;
    armv6)
      EXTRA_CFLAGS="-march=armv6"
      EXTRA_LDFLAGS=""
      ;;
    *)
      EXTRA_CFLAGS=""
      EXTRA_LDFLAGS=""
      ;;
  esac

  PREFIX="$DEST/$version" && mkdir -p $PREFIX
  FFMPEG_FLAGS="$FFMPEG_FLAGS --prefix=$PREFIX"

  ./configure $FFMPEG_FLAGS --extra-cflags="$CFLAGS $EXTRA_CFLAGS" --extra-ldflags="$EXTRA_LDFLAGS" | tee $PREFIX/configuration.txt
  cp config.* $PREFIX
  [ $PIPESTATUS == 0 ] || exit 1

  make clean
  make -j4 || exit 1
  make install || exit 1
  
  $AR d libavcodec/libavcodec.a inverse.o  
  $AR d libavcodec/libavcodec.a log2_tab.o
  $AR d libavutil/libavutil.a log2_tab.o
  
  $LD -rpath-link=$SYSROOT/usr/lib -L$SYSROOT/usr/lib \
   -soname libffmpeg.so -shared -nostdlib -z noexecstack \
   -Bsymbolic --whole-archive --no-undefined \
   -o $PREFIX/libffmpeg.so libavcodec/libavcodec.a libavformat/libavformat.a libavutil/libavutil.a libswscale/libswscale.a \
   -lc -lm -lz -ldl -llog --dynamic-linker=/system/bin/linker $PREBUILT/lib/gcc/arm-linux-androideabi/4.8/libgcc.a  

  cp $PREFIX/libffmpeg.so $PREFIX/libffmpeg-debug.so
  $STRIP --strip-unneeded $PREFIX/libffmpeg.so

done
