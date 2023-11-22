#!/bin/bash

set -x
set -e

BUILD_DIR=`pwd`/build
PATH=$BUILD_DIR/bin:$PATH

#
# yasm
#
build_yasm() {
  YASM_VERSION=1.3.0

  if [ ! -d yasm-$YASM_VERSION ]; then
      if [ ! -f yasm-$YASM_VERSION.tar.gz ]; then
          wget http://www.tortall.net/projects/yasm/releases/yasm-$YASM_VERSION.tar.gz
      fi
      tar xzf yasm-$YASM_VERSION.tar.gz
  fi

  cd yasm-$YASM_VERSION
  ./configure --prefix="$BUILD_DIR" --bindir="$BUILD_DIR/bin"
  make -j 4
  make install
  cd ..
}

#
# nasm
#
build_nasm() {
  NASM_VERSION=2.16.01

  if [ ! -d nasm-$NASM_VERSION ]; then
      if [ ! -f nasm-$NASM_VERSION.tar.gz ]; then
          wget https://www.nasm.us/pub/nasm/releasebuilds/$NASM_VERSION/nasm-$NASM_VERSION.tar.gz
      fi
      tar xzf nasm-$NASM_VERSION.tar.gz
  fi

  pushd nasm-$NASM_VERSION
  ./configure --prefix="$BUILD_DIR" --bindir="$BUILD_DIR/bin"
  make -j 4
  make install
  popd
}

#
# libx264
#
build_libx264() {
  X264_PATH=x264-snapshot-stable-2023-10-01
  if [ ! -d $X264_PATH ]; then 
      git clone https://code.videolan.org/videolan/x264.git $X264_PATH
      # 31e19f92f00c7003fa115047ce50978bc98c3a0d(Sun Oct 1 17:28:26 2023 +0300, "ppc: Fix compilation on unknown OS")
      # is the last commit on origin/stable branch(https://code.videolan.org/videolan/x264/-/commits/stable/)
      cd $X264_PATH
      git checkout 31e19f92f00c7003fa115047ce50978bc98c3a0d
  else
      cd $X264_PATH
      # reset local changes to avoid 'M' (modified) suffix to be added to library version when re-building the library
      git checkout .
  fi

  ./configure --prefix="$BUILD_DIR" --bindir="$BUILD_DIR/bin" --enable-shared --enable-pic --disable-cli --disable-gpl
  # rename library to libx264-nimble.so
  sed -i -e 's/SONAME=libx264.so/SONAME=libx264-nimble.so/' config.mak
  sed -i -e 's/libx264.$(SOSUFFIX)/libx264-nimble.$(SOSUFFIX)/' Makefile
  make -j 4
  make install
  cd ..
}

#
# libfdk-aac
#
build_libfdkaac() {
  if [ ! -d fdk-aac ]; then
    git clone https://github.com/mstorsjo/fdk-aac.git
    cd fdk-aac
  else
    cd fdk-aac
    git fetch
  fi

  # 4de681c193d45b14f87efc30e3e3f02d389387b5 is currently available latest version of the lib
  git checkout 4de681c193d45b14f87efc30e3e3f02d389387b5
  ./autogen.sh
  ./configure --enable-shared --enable-static=no --with-pic --prefix="$BUILD_DIR" --libdir="$BUILD_DIR/lib"
  sed -i -e 's/libfdk-aac.la/libfdk-aac-nimble.la/' Makefile
  make -j 4
  make install
  cd ..
}

#
# libmp3lame
#
build_libmp3lame() {
  LAME_VERSION=3.100

  if [ ! -d lame-$LAME_VERSION ]; then
      if [ ! -f lame-$LAME_VERSION.tar.gz ]; then
          wget https://freefr.dl.sourceforge.net/project/lame/lame/3.100/lame-$LAME_VERSION.tar.gz
      fi
      tar xf lame-$LAME_VERSION.tar.gz
  fi

  pushd lame-$LAME_VERSION
  ./configure \
   --prefix="$BUILD_DIR" \
   --libdir="$BUILD_DIR/lib" \
   --enable-shared \
   --disable-static \
   --disable-decoder \
   --disable-frontend \
   --disable-mp3x \
   --disable-mp3rtp \
   --disable-dynamic-frontends
  sed -i -e 's/libmp3lame\.la/libmp3lame-nimble.la/' libmp3lame/Makefile
  make -j 4
  make install
  popd
}

#
# libvpx
#
build_libvpx() {
  # do not build libvpx on macOS
  if [ `uname` != "Darwin" ]; then
    if [ ! -d libvpx ]; then
        git clone https://chromium.googlesource.com/webm/libvpx
        pushd libvpx
    else
      pushd libvpx
      git fetch
      git checkout . # discard local changes
    fi

    git checkout v1.13.1
    ./configure --prefix="$BUILD_DIR" --target=x86_64-linux-gcc --enable-shared --disable-examples --disable-tools --disable-docs --disable-unit-tests --disable-decode-perf-tests --disable-encode-perf-tests

    # add suffix to lib name
    sed -i -e 's/libvpx.so/libvpx-nimble.so/g' libs.mk
    make clean
    make -j 4
    make install
    popd
  else
      echo "skip building libvpx on macOS"
  fi
}

#
# svt-hevc
#
build_libsvthevc() {
  # do not build svt-hevc on macOS
  if [ `uname` != "Darwin" ]; then
    if [ ! -d svt-hevc ]; then
        git clone https://github.com/OpenVisualCloud/SVT-HEVC.git svt-hevc
    fi

    pushd svt-hevc
    git fetch
    # discard local changes
    git checkout .
    # latest current version of svt as of Oct 16, 2023
    git checkout 6cca5b932623d3a1953b165ae6b093ca1325ac44
    sed -i -e 's/SvtHevcEnc$/SvtHevcEnc-nimble/' ./Source/Lib/Codec/CMakeLists.txt
    sed -i -e 's/SvtHevcEnc.pc/SvtHevcEnc-nimble.pc/' ./Source/Lib/Codec/CMakeLists.txt
    # update SvtHevcEncApp dependency name
    sed -i -e 's/SvtHevcEnc)/SvtHevcEnc-nimble)/' ./Source/App/CMakeLists.txt
    cmake . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" -DCMAKE_INSTALL_LIBDIR=lib
    make -j 4
    make install
    popd
  else
      echo "skip building svt-hevc on macOS"
  fi
}

build_libopus() {
  OPUS_VERSION=1.3.1

  if [ -d opus-$OPUS_VERSION ]; then
      rm -rf opus-$OPUS_VERSION
  fi

  if [ ! -f opus-$OPUS_VERSION.tar.gz ]; then
      wget https://archive.mozilla.org/pub/opus/opus-$OPUS_VERSION.tar.gz
  fi
  tar xzf opus-$OPUS_VERSION.tar.gz

  pushd opus-$OPUS_VERSION
  sed -i -e 's/-lopus/-lopus-nimble/' opus.pc.in
  ./configure --prefix="$BUILD_DIR" --bindir="$BUILD_DIR/bin" --enable-static=no
  sed -i -e 's/libname_spec=\"lib\\$name\"/libname_spec=\"lib\\$name-nimble\"/g' libtool
  # V=1 can be added as make argument to enable verbose logging
  make -j 4
  sed -i -e 's/libopus.so/libopus-nimble.so/g' libopus.la
  make install
  popd
}

build_libaom() {
  if [ ! -d aom ]; then
    git clone https://aomedia.googlesource.com/aom aom
  fi

  pushd aom
  git fetch
  # discard local changes
  git checkout .
  git checkout v3.6.1

  # libaom -> libaom-nimble
  git apply ../aom_libname.patch
  popd 

  if [ -d aom_build ]; then
      rm -rf aom_build
  fi

  mkdir -p aom_build
  pushd aom_build
  cmake ../aom -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=1 -DCONFIG_AV1_ENCODER=1 -DCONFIG_AV1_DECODER=0 -DENABLE_TOOLS=0 -DENABLE_DOCS=0 -DENABLE_EXAMPLES=0 -DENABLE_TESTS=0 -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" -DCMAKE_INSTALL_LIBDIR=lib
  make -j4 

  # cmake ignores OUTPUT_NAME on .pc file generation, so we have to change libname with sed
  sed -i -e 's/-laom/-laom-nimble/' aom.pc

  make install
  popd
}

build_libdav1d() {
  if [ ! -d dav1d ]; then
    git clone https://code.videolan.org/videolan/dav1d.git dav1d
  fi

  pushd dav1d  
  git fetch
  # discard local changes
  git checkout .
  git checkout 1.3.0
  sed -i -e "s/library('dav1d'/library('dav1d-nimble'/" src/meson.build
  popd

  if [ -d dav1d_build ]; then
      rm -rf dav1d_build
  fi

  mkdir -p dav1d_build
  pushd dav1d_build  
  meson setup ../dav1d

  meson configure --prefix="$BUILD_DIR" --libdir=lib
  ninja	install 
  popd
}

build_libsvtav1() {
  if [ ! -d svt_av1 ]; then
    git clone https://gitlab.com/AOMediaCodec/SVT-AV1.git svt_av1
  fi

  pushd svt_av1
  git fetch
  git checkout .
  git checkout v1.4.1

  # turn off all stdout library log
  git apply ../svt_av1_log_quiet.patch

  # rename SvtAv1Enc to SvtAv1Enc-nimble
  git apply ../svt_av1_libname.patch
  popd

  rm -rf svt_av1_build
  mkdir svt_av1_build
  pushd svt_av1_build
  cmake ../svt_av1 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DBUILD_ENC=ON -DBUILD_DEC=OFF -DBUILD_TESTING=OFF -DBUILD_APPS=OFF \
                   -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" -DCMAKE_INSTALL_LIBDIR=lib ../svt_av1
  cmake --build . --target SvtAv1Enc --config Release -- -j 8
  cmake --install . --config Release
  popd
}

#
# ffmpeg
#
build_ffmpeg() {
  FFMPEG_VERSION=5.1.3
  build_with_nvenc_av1_cuvid=false

  codename="centos"
  if [ -f /etc/lsb-release ]; then
    set +e # ignore grep exit status or script fails if grep did not match
    codename=`cat /etc/lsb-release | grep -oP "^DISTRIB_CODENAME=\K.*"`
    set -e
  fi

  if [ "$codename" == "bionic" ] || [ "$codename" == "disco" ] || [ "$codename" == "eoan" ]; then
      build_with_nvenc=1
      build_with_quicksync=0
      echo "building FFmpeg for $codename with NVENC encoders/decoders support"
  elif [ "$codename" == "focal" ] || [ "$codename" == "jammy" ]; then
      build_with_nvenc=1
      build_with_quicksync=1
      echo "building FFmpeg for $codename with NVENC/QUICKSYNC encoders/decoders support"
  else
      build_with_nvenc=0
      build_with_quicksync=0
      echo "building FFmpeg for $codename without NVENC/QUICKSYNC encoders/decoders support"
  fi

  if [ $build_with_nvenc == 1 ]; then
      if [ ! -d nv-codec-headers ]; then
          git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
      fi

      pushd nv-codec-headers
      # !!!!!!!!!!IMPORTANT NOTE !!!!!!!!!!!!!
      # when you change nv-codec-headers's revision, "nimble native nvenc" and "ffmpeg's nvenc" may stop working
      # because nvenc api version in choosen nv-codec-headers revision may be greater than nvenc api version supported by installed driver

      if [ $build_with_nvenc_av1_cuvid == false ]; then
        git checkout n8.2.15.10 # smallest api version required by nvenc support in ffmpeg
      else
        git checkout n11.0.10.0 # av1_cuvid requires at least n11
      fi

      # -e force make to apply environment PREFIX value instead of default one
      PREFIX="$BUILD_DIR" make -j 8 -e install
      popd
  fi


  if [ ! -d ffmpeg-$FFMPEG_VERSION ]; then
      if [ ! -f ffmpeg-$FFMPEG_VERSION.tar.bz2 ]; then
          wget http://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2
      fi
      tar xjf ffmpeg-$FFMPEG_VERSION.tar.bz2

      if [ "$FFMPEG_VERSION" == "5.1.3" ]; then
        # clear qsv encoder frame type to avoid extra keyframe insertion causes quality loss
        # https://patchwork.ffmpeg.org/project/ffmpeg/list/?series=2545
        md5sum -c qsvenc.c.5.1.3.original.md5
        patch  ffmpeg-5.1.3/libavcodec/qsvenc.c qsvenc.c.4.3.2.FrameType.patch

        # overlay_qsv filter forced each output frame to be key frame so we have
        # to copy frame props of frame coming to main input to output frame
        md5sum -c vf_overlay_qsv.c.5.1.3.original.md5
        patch  ffmpeg-5.1.3/libavfilter/vf_overlay_qsv.c vf_overlay_qsv_frame_props.patch
      fi
  fi

  # for ubuntu 18.04 - apt-get install libfreetype-dev libmfx-dev libspeex-dev libva-dev nvidia-cuda-dev libnppicc9.1 libnppig9.1
  # for ubuntu 19.04 - apt-get install libfreetype-dev libmfx-dev libspeex-dev libva-dev nvidia-cuda-dev libnppicc10 libnppig10
  # for ubuntu 20.04 - apt-get install libfreetype-dev libmfx-dev libspeex-dev libva-dev nvidia-cuda-dev libnppicc10 libnppig10 nvidia-cuda-toolkit
  # for ubuntu 22.04 - apt-get install libfreetype-dev libmfx-dev libspeex-dev libva-dev nvidia-cuda-dev libnppicc11 libnppig11 nvidia-cuda-toolkit

  if [ $build_with_nvenc == 1 ]; then
      FFMPEG_ENCODERS="aac,png,mjpeg,h264_nvenc,hevc_nvenc"
      FFMPEG_DECODERS="aac,pcm_alaw,pcm_mulaw,mp2,h264,mpeg2video,mp3,png,mjpeg,tiff,gif,bmp,libspeex,hevc,vp8,vp9,ac3,h264_cuvid,hevc_cuvid,mpeg2_cuvid,vp8_cuvid,vp9_cuvid"

      if [ $build_with_nvenc_av1_cuvid == true ]; then
        FFMPEG_DECODERS+=",av1_cuvid"
      fi

      FFMPEG_CUVID_OPTIONS="--enable-cuvid --enable-nonfree --enable-libnpp --enable-cuda-nvcc"
  else
      FFMPEG_ENCODERS="aac,png,mjpeg"
      FFMPEG_DECODERS="aac,pcm_alaw,pcm_mulaw,mp2,h264,mpeg2video,mp3,png,mjpeg,tiff,gif,bmp,libspeex,hevc,vp8,vp9,ac3"
      FFMPEG_CUVID_OPTIONS=
  fi

  if [ $build_with_quicksync == 1 ]; then
      FFMPEG_DECODERS+=",h264_qsv,hevc_qsv,vp8_qsv,vp9_qsv"
      FFMPEG_ENCODERS+=",h264_qsv,hevc_qsv"
      FFMPEG_QUICKSYNC_OPTIONS="--enable-vaapi --enable-libmfx"
  else
      FFMPEG_QUICKSYNC_OPTIONS="--disable-vaapi"
  fi

  FFMPEG_DECODERS+=",libopus"
  FFMPEG_ENCODERS+=",libopus"

  FFMPEG_ENCODERS+=",mp2"

  FFMPEG_DECODERS+=",libdav1d"
  FFMPEG_ENCODERS+=",libaom_av1,libsvtav1"

  cd ffmpeg-$FFMPEG_VERSION
  if [ $build_with_nvenc == 1 ] && [ "$codename" == "jammy" ]; then
    # nvcc 11.5 on Ubuntu 22.04 fails during configure with the following error:
    # nvcc fatal   : Unsupported gpu architecture 'compute_30'
    # 'nvcc --help' output shows that compute_35 is minimum architecture version allowed

    # it should be possible to override default nvccflags with --nvccflags="-gencode arch=compute_35,code=sm_35 -O2" option
    # but I was not able to do that using variable passed as argument to configure
    sed -i -e 's/arch=compute_30,code=sm_30/arch=compute_35,code=sm_35/' configure
  fi
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
    --enable-decoder=$FFMPEG_DECODERS \
    --disable-encoders   \
    --enable-encoder=$FFMPEG_ENCODERS \
    --disable-muxers     \
    --disable-demuxers   \
    --enable-demuxer=mov,image2,gif,mp3,webm_dash_manifest \
    --disable-parsers    \
    --disable-bsfs       \
    --disable-protocols  \
    --enable-protocol=file \
    --disable-indevs     \
    --disable-outdevs    \
    $FFMPEG_QUICKSYNC_OPTIONS \
    --enable-filters     \
    --disable-ffmpeg     \
    --disable-ffprobe    \
    --disable-ffplay     \
    --enable-libspeex    \
    --enable-libfreetype \
    $FFMPEG_CUVID_OPTIONS \
    --enable-libopus     \
    --enable-libaom      \
    --enable-libdav1d    \
    --enable-libsvtav1   \
    --disable-manpages
    #--enable-gpl \
    #--enable-nonfree
  make -j 4
  make install
}

build_yasm
build_nasm
build_libx264
build_libfdkaac
build_libmp3lame
build_libvpx
build_libsvthevc
build_libopus
build_libaom
build_libdav1d
build_libsvtav1
build_ffmpeg
