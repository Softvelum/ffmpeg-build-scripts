# docker environment to build nimble transcoder libraries for Ubuntu 24.04
#
# Build and run:
#   docker build -t nimble-ffmpeg-builder-ubuntu-24.04 -f Dockerfile .
#   docker run -d nimble-ffmpeg-builder-ubuntu-24.04
#
# Copy files:
# docker cp $CID:/home/builder/ffmpeg/build/lib ./lib

FROM ubuntu:24.04

RUN apt-get update
RUN apt-get -y install apt-utils tzdata

RUN apt-get -y install sudo rsync vim less wget curl tar git build-essential gcc g++ \
                       make cmake meson ninja-build autoconf automake autopoint iproute2

RUN useradd -G sudo -m -s /bin/bash builder \
    && yes password | passwd builder \
    && echo '\nbuilder  ALL=(ALL) NOPASSWD: /usr/bin/apt-get' >> /etc/sudoers

# install ffmpeg dependencies
RUN apt-get install -y \
        fakeroot expect tcl devscripts pkg-config \
        libssl-dev libxml2-dev libbz2-dev libzip-dev libjson-c-dev \
        libfreetype6-dev libspeex-dev libtool avahi-utils libharfbuzz-dev \
        libva-dev libmfx-dev nvidia-cuda-toolkit

USER builder
RUN mkdir /home/builder/ffmpeg
COPY build_scripts/* /home/builder/ffmpeg/

# build ffmpeg libraries
RUN cd /home/builder/ffmpeg \
    && ./make_libs_ffmpeg_6.1.2.sh