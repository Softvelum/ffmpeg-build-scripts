#!/bin/bash

AVCODEC_PATH=`dpkg -L nimble-transcoder | grep -m 1 libavcodec-nimble`
if [ -z "$AVCODEC_PATH" ]; then
  echo "nimble-transcoder is not installed. Please install the package, then run $0 again."
  exit 1
fi 

LIB_PATH=${AVCODEC_PATH%/*}
if [ -w "$LIB_PATH" ]; then
  cp -v lib/*.so* $LIB_PATH
else
  echo "Root privileges are required to copy libraries to $LIB_PATH"
  sudo cp -v lib/*.so* $LIB_PATH
fi
if [ $? -eq 0 ]; then
    echo "Libraries copied successfully."
else
    echo "Failed to copy libraries to $LIB_PATH"
fi