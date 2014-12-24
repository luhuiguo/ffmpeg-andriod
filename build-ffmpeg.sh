#!/bin/bash

FF_TARGET=$1
set -e
set +x

FF_ALL_ARCHS="armv5 armv7a arm64-v8a x86"
FF_ACT_ARCHS="armv5 armv7a x86"

echo_archs() {
    echo "===================="
    echo "[*] check archs"
    echo "===================="
    echo "FF_ALL_ARCHS = $FF_ALL_ARCHS"
    echo "FF_ACT_ARCHS = $FF_ACT_ARCHS"
    echo ""
}

#----------
case "$FF_TARGET" in
    "")
        echo_archs
        sh compile-ffmpeg.sh armv7a
    ;;
    armv5|armv7a|x86|arm64-v8a)
        echo_archs
        sh compile-ffmpeg.sh $FF_TARGET
    ;;
    all)
        echo_archs
        for ARCH in $FF_ACT_ARCHS
        do
            sh compile-ffmpeg.sh $ARCH
        done
    ;;
    clean)
        echo_archs
        for ARCH in $FF_ALL_ARCHS
        do
            cd ffmpeg && git clean -xdf && cd -
        done
        rm -rf ./build/ffmpeg-*
    ;;
    check)
        echo_archs
    ;;
    *)
        echo "Usage:"
        echo "  build-ffmpeg.sh armv5|armv7a|x86|arm64-v8a"
        echo "  build-ffmpeg.sh all"
        echo "  build-ffmpeg.sh clean"
        echo "  build-ffmpeg.sh check"
        exit 1
    ;;
esac

