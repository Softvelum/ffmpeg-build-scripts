# FFmpeg build scripts examples

Here you can find examples of FFmpeg build scripts which can be used for creating its custom builds. Libraries from those builds can be used for extending the functionality of Nimble Streamer [Live Transcoder](https://softvelum.com/transcoder/).

**Legal notice**

Every custom library which is a result of building FFmpeg has its own licensing terms. So every library must be examined for its licensing terms prior to any usage or distribution, including but not limited to the patent licensing terms. Softvelum, LLC is not responsible for any license or patent infringement which can occur as a result of any FFmpeg custom build usage by Live Transcoder users.

**Default build**

All FFmpeg packages and their respective builds [can be found here](http://nimblestreamer.com/sources/ffmpeg/).

build_ffmpeg_4.3.2.sh  - use this script to build FFmpeg 4.3.2, the latest FFmpeg supported by Nimble Streamer

build_ffmpeg_4.1.4.sh  - use this script to build FFmpeg 4.1.4


**Building with libx265**

build_ffmpeg_4.1.4_libx265.sh - this script builds FFmpeg 4.1.4 with libx265

Building this library will require libx265-dev package to be installed. Run these commands for installation:

For Ubuntu:

apt-get install libx265-dev

For CentOS:

yum install libx265-dev


**Building with AC3 and E-AC3**

build_ffmpeg_4.1.4_ac3.sh - this script builds FFmpeg 4.1.4 with AC3 and E-AC3 encoder libraries.
