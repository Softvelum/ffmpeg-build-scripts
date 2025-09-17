#!/bin/bash

##########################################################################
### Builds custom FFmpeg libraries for Nimble Transcoder using Docker
### Can be used for Ubuntu 20.04, 22.04, 24.04
### When called without parameters builds libraries for host Ubuntu version
###  and asks to copy it to /lib/ directory (superuser permissions required)
### You can specify `-r <version>`` to build for specific version and
### `-c y`` or `-c n`` to copy libraries or skip copying without user request
### For more information visit https://blog.wmspanel.com/2020/01/ffmpeg-custom-build-support.html
##########################################################################

while getopts "r:c:h" opt; do
  case $opt in
    r)
      ubuntu_ver="$OPTARG"
      ;;
    c)
      COPY_FILES="$OPTARG"
      ;;
    h)
      echo "Usage: $0"
      echo "  -r <20.04|22.04|24.04> -- Build for specific Ubuntu version (host version used when omitted)"
      echo "  -c y|n                 -- Copy files to /lib if 'y', skip copy if 'n', ask for copying otherwise"
      echo "  -h                     -- Show this text"
      exit 0
      ;;
    ?)
      echo "Error: Unknown option. Call $0 -h for list of options" >&2
      exit 1
      ;;      
  esac
done

if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running - please start it and try again"
  exit 1
fi

if [ -z "${ubuntu_ver}" ] ; then
  if [ -f /etc/lsb-release ]; then
    ubuntu_ver=`cat /etc/lsb-release | grep -oP "^DISTRIB_RELEASE=\K.*"`
  fi
fi 

if [ "$ubuntu_ver" != "20.04" ] && [ "$ubuntu_ver" != "22.04" ] && [ "$ubuntu_ver" != "24.04" ]; then
    echo "Only Ubuntu 20.04, 22.04 and 24.04 are supported"
    exit 1
fi

rm -rf lib/

image_name="nimble-ffmpeg-builder-ubuntu-$ubuntu_ver"

docker build -t $image_name -f "ubuntu-$ubuntu_ver/Dockerfile" .
if [ $? -ne 0 ]; then
  echo "Build failed"
  exit 1
fi

CID=$(docker run -d $image_name)
docker cp --follow-link $CID:/home/builder/ffmpeg/build/lib ./lib
if [ -f "lib/libavformat-nimble.so" ]
then
  echo "FFmpeg libraries have been built and copied to lib/ directory"
  docker stop $CID
  docker rm $CID
else
  echo "Failed to copy libraries"
  exit 1
fi

if [ "$COPY_FILES" == "y" ] || [ "$COPY_FILES" == "n" ] ; then
  IS_COPY=$COPY_FILES
else 
  AVCODEC_PATH=`dpkg -L nimble-transcoder | grep -m 1 libavcodec-nimble`
  if [ -z "$AVCODEC_PATH" ]; then
    echo "nimble-transcoder is not installed. Please install the package, then run ./copy_libs.sh again."
    exit 1
  fi
  AVCODEC_PATH=${AVCODEC_PATH%/*}

  read -p "Copy built libraries to $AVCODEC_PATH? [Y/n] " IS_COPY
fi
if [ -z "${IS_COPY}" ] || [[ $IS_COPY =~ ^[Yy] ]]; then
  ./copy_libs.sh
fi