#!/bin/bash

set -x
set -e

BUILD_DIR=`pwd`/build
PATH=$BUILD_DIR/bin:$PATH

#
# ffmpeg
#
build_ffmpeg() {
  FFMPEG_VERSION=4.3.2

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
  elif [ "$codename" == "focal" ]; then      
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
      git checkout n8.2.15.10
      # -e force make to apply environment PREFIX value instead of default one
      PREFIX="$BUILD_DIR" make -j 8 -e install
      popd
  fi


  if [ ! -d ffmpeg-$FFMPEG_VERSION ]; then
      if [ ! -f ffmpeg-$FFMPEG_VERSION.tar.bz2 ]; then
          wget http://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2
      fi
      tar xjf ffmpeg-$FFMPEG_VERSION.tar.bz2

      if [ "$FFMPEG_VERSION" == "4.3.2" ]; then
        # I found memory leak in ffmpeg qsv encoder. There is no fixes in ffmpeg master as of now but I've filed a patch request against ffmpeg
        # https://patchwork.ffmpeg.org/project/ffmpeg/list/?series=1992
        md5sum -c qsvenc.c.4.3.2.original.md5
        patch  ffmpeg-4.3.2/libavcodec/qsvenc.c qsvenc.c.4.3.2.patch

        # clear qsv encoder frame type to avoid extra keyframe insertion causes quality loss
        # https://patchwork.ffmpeg.org/project/ffmpeg/list/?series=2545
        patch  ffmpeg-4.3.2/libavcodec/qsvenc.c qsvenc.c.4.3.2.FrameType.patch

        # overlay_qsv filter forced each output frame to be key frame so we have
        # to copy frame props of frame coming to main input to output frame
        md5sum -c vf_overlay_qsv.c.4.3.2.original.md5
        patch  ffmpeg-4.3.2/libavfilter/vf_overlay_qsv.c vf_overlay_qsv_frame_props.patch
      fi
  fi

  # for ubuntu 18.04 - apt-get install libfreetype-dev libmfx-dev libspeex-dev libva-dev nvidia-cuda-dev libnppicc9.1 libnppig9.1
  # for ubuntu 19.04 - apt-get install libfreetype-dev libmfx-dev libspeex-dev libva-dev nvidia-cuda-dev libnppicc10 libnppig10
  # for ubuntu 20.04 - apt-get install libfreetype-dev libmfx-dev libspeex-dev libva-dev nvidia-cuda-dev libnppicc10 libnppig10 nvidia-cuda-toolkit

  if [ $build_with_nvenc == 1 ]; then
      FFMPEG_ENCODERS="aac,png,mjpeg,h264_nvenc,hevc_nvenc"
      FFMPEG_DECODERS="aac,pcm_alaw,pcm_mulaw,mp2,h264,mpeg2video,mp3,png,mjpeg,tiff,gif,bmp,libspeex,hevc,vp8,vp9,ac3,h264_cuvid,hevc_cuvid,mpeg2_cuvid"
      FFMPEG_CUVID_OPTIONS="--enable-cuvid --enable-nonfree --enable-libnpp --enable-cuda-nvcc"
  else
      FFMPEG_ENCODERS="aac,png,mjpeg"
      FFMPEG_DECODERS="aac,pcm_alaw,pcm_mulaw,mp2,h264,mpeg2video,mp3,png,mjpeg,tiff,gif,bmp,libspeex,hevc,vp8,vp9,ac3"
      FFMPEG_CUVID_OPTIONS=
  fi

  if [ $build_with_quicksync == 1 ]; then
      FFMPEG_DECODERS+=",h264_qsv,hevc_qsv"
      FFMPEG_ENCODERS+=",h264_qsv,hevc_qsv"
      FFMPEG_QUICKSYNC_OPTIONS="--enable-vaapi --enable-libmfx"
  else
      FFMPEG_QUICKSYNC_OPTIONS="--disable-vaapi"
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
    --disable-manpages
    # DEBUGGING NOTE: 1) remove all code from DynamicLibrary::Close() or add "return" at function start as sanitizer will not work for dynamic libs if you unload them
    # DEBUGGING NOTE: 2) uncomment line below(starting with --disable-stripping) if you need to debug ffmpeg internals or if you need to see callstack in sanitizer report.
    #                    on 4.2.4 I had to remove "ac3" from FFMPEG_DECODERS to build with -disable-optimizations. maybe in new ffmpeg versions this will be fixed
    #--disable-stripping --enable-debug=3 --disable-optimizations
    #--pkg-config-flags="--static" \
    #--enable-gpl \
    #--enable-libass \
    #--enable-libfdk-aac \
    #--enable-libmp3lame \
    #--enable-libopus \
    #--enable-libtheora \
    #--enable-libvorbis \
    #--enable-libvpx \
    #--enable-libx264 \
    #--enable-libx265 \
    #--enable-nonfree
  make -j 4
  make install
  # make distclean
  # hash -r
}

build_ffmpeg
