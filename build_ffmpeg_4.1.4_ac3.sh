#!/bin/bash

set -x
set -e

BUILD_DIR=`pwd`/build
PATH=$BUILD_DIR/bin:$PATH

#
# yasm
#
YASM_VERSION=1.3.0

if [ ! -d yasm-$YASM_VERSION ]
then
    if [ ! -f yasm-$YASM_VERSION.tar.gz ]
    then
        wget http://www.tortall.net/projects/yasm/releases/yasm-$YASM_VERSION.tar.gz
    fi
    tar xzf yasm-$YASM_VERSION.tar.gz
fi

cd yasm-$YASM_VERSION
./configure --prefix="$BUILD_DIR" --bindir="$BUILD_DIR/bin"
make -j 4
make install
# make distclean
cd ..

#
# nasm
#
NASM_VERSION=2.14.02

if [ ! -d nasm-$NASM_VERSION ]
then
    if [ ! -f nasm-$NASM_VERSION.tar.gz ]
    then
        wget https://www.nasm.us/pub/nasm/releasebuilds/$NASM_VERSION/nasm-$NASM_VERSION.tar.gz
    fi
    tar xzf nasm-$NASM_VERSION.tar.gz
fi

pushd nasm-$NASM_VERSION
./configure --prefix="$BUILD_DIR" --bindir="$BUILD_DIR/bin"
make -j 4
make install
# make distclean
popd

#
# ffmpeg
#
FFMPEG_VERSION=4.1.4

if [ ! -d ffmpeg-$FFMPEG_VERSION ]
then
    if [ ! -f ffmpeg-$FFMPEG_VERSION.tar.bz2 ]
    then
        wget http://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2
    fi
    tar xjf ffmpeg-$FFMPEG_VERSION.tar.bz2
fi

cd ffmpeg-$FFMPEG_VERSION
PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig ./configure \
  --prefix="$BUILD_DIR" \
  --extra-cflags="-I$BUILD_DIR/include" \
  --extra-ldflags="-L$BUILD_DIR/lib" \
  --bindir="$BUILD_DIR/bin" \
  --build-suffix=-nimble \
  --disable-static     \
  --enable-shared      \
  --enable-pic         \
  --disable-decoders   \
  --enable-decoder=aac,pcm_alaw,pcm_mulaw,mp2,h264,mpeg2video,mp3,png,mjpeg,tiff,gif,bmp,libspeex,hevc,vp8,vp9,ac3,eac3 \
  --disable-encoders   \
  --enable-encoder=aac,png,mjpeg,ac3,eac3 \
  --disable-muxers     \
  --disable-demuxers   \
  --enable-demuxer=mov,image2,gif,mp3,webm_dash_manifest \
  --disable-parsers    \
  --disable-bsfs       \
  --disable-protocols  \
  --enable-protocol=file \
  --disable-indevs     \
  --disable-outdevs    \
  --disable-vaapi      \
  --enable-filters     \
  --disable-ffmpeg     \
  --disable-ffprobe    \
  --disable-ffplay     \
  --enable-libspeex    \
  --enable-libfreetype \
  --disable-manpages
make -j 4
make install
