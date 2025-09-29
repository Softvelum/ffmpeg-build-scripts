# FFmpeg build scripts examples

Here you can find examples of FFmpeg build scripts which can be used for creating its custom builds. Libraries from those builds can be used for extending the functionality of Nimble Streamer [Live Transcoder](https://softvelum.com/transcoder/).

## Legal notice

This article explains how to build custom third-party FFmpeg libraries and use them in Nimble Live Transcoder, alongside the libraries included in the standard Live Transcoder package. Each custom-built FFmpeg library is subject to its own licensing terms. Therefore, every library must be reviewed for licensing compliance before use or distribution, including any associated patent licensing terms. Softvelum is not responsible for any license or patent infringement that may result from the use of custom FFmpeg builds in Live Transcoder.

## Articles

Read [FFmpeg custom build support in Live Transcoder](https://blog.wmspanel.com/2020/01/ffmpeg-custom-build-support.html) to learn more about using custom builds woth Live Transcoder. Also take a look at [NETINT encoder support in Nimble Streamer Transcoder](https://blog.wmspanel.com/2021/11/netint-support-nimble-transcoder_01580972231.html) as an example.


## Docker-based build

If you'd like a simple procedure, use our script from "ffmpeg-docker-builder" directory, it creates a Docket image where the build is made, which simplifies the process.\
It's compatible with Ubuntu 20.04, 22.04 and 24.04.

[Read full description article](https://softvelum.com/2025/09/docker-custom-ffmpeg-nimble-transcoder/) for usage details.

If you need other OSes or libraries, follow the instructions below.

## Default build

All FFmpeg packages and their respective builds [can be found here](http://nimblestreamer.com/sources/ffmpeg/).

5.1.3/build_nimble_transcoder_ffmpeg_5.1.3.sh - use this script to build FFmpeg 5.1.3, the latest FFmpeg supported by Nimble Streamer

build_ffmpeg_4.3.2.sh - use this script to build FFmpeg 4.3.2

build_ffmpeg_4.1.4.sh - use this script to build FFmpeg 4.1.4


## Building with libx265

build_ffmpeg_4.1.4_libx265.sh - this script builds FFmpeg 4.1.4 with libx265

Building this library will require libx265-dev package to be installed. Run these commands for installation:

For Ubuntu:

apt-get install libx265-dev

For CentOS:

yum install libx265-dev


## Building with AC3 and E-AC3

5.1.3/build_nimble_transcoder_ffmpeg_5.1.3_with-eac3.sh - this script builds FFmpeg 5.1.3 with AC3 and E-AC3 encoders.

build_ffmpeg_4.1.4_ac3.sh - this script builds FFmpeg 4.1.4 with AC3 and E-AC3 encoders.
