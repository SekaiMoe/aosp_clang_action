#!/usr/bin/env bash

# shellcheck disable=SC2086,SC2154,SC2155,SC2046,SC2001,SC2063

set -eux

if [[ "${GITHUB_ACTIONS}" != "true" || "${OSTYPE}" != "linux-gnu" ]]; then
  if [ ! -f /usr/bin/apt ]; then
    printf "This Action Is Intended For Ubuntu Runner.\n"
    exit 1
  fi
fi

curl -SsL https://github.com/rokibhasansagar/slimhub_actions/raw/main/cleanup.sh | bash

sudo apt update
sudo apt install -y git libssl-dev gcc-arm-linux-gnueabi build-essential libncurses5-dev bzip2 make gcc g++ grep bc curl bison flex openssl lzop ccache unzip zlib1g-dev file ca-certificates ccache wget cmake texinfo ca-certificates zlib1g-dev xz-utils libelf-dev zip libgmp-dev xz-utils libncurses-dev g++ gawk m4 libtinfo5 cpio binutils-dev libelf-dev cmake ninja-build texinfo u-boot-tools python2-minimal python2 zstd clang

test -d out || mkdir -p out
export install_path=./out

git clone https://android.googlesource.com/platform/external/toolchain-utils --recursive
git clone https://android.googlesource.com/toolchain/binutils --recursive
git clone https://android.googlesource.com/toolchain/llvm_android --recursive
git clone https://android.googlesource.com/toolchain/llvm-project --recursive

cd toolchain-utils
git checkout "$util_hash"
cd ..

cd llvm-project
git checkout "$version_hash"
cd ..

cd llvm_android
git checkout "$android_hash"
cd ..

export versionss=$(echo "$clang_version" | sed 's/r\([0-9]\+\)[a-zA-Z]\?/\1/g')

python3 toolchain-utils/llvm_tools/patch_manager.py --svn_version "$versionss" --patch_metadata_file llvm_android/patches/PATCHES.json --filesdir_path llvm_android/patches --src_path llvm-project --use_src_head --failure_mode fail

cd llvm-project
mkdir build
cd build
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" \
  -DLLVM_TARGETS_TO_BUILD="AArch64;ARM" \
  -DLLVM_BUILD_TESTS=OFF \
  -DLLVM_ENABLE_WARNINGS=OFF \
  -DCMAKE_INSTALL_PREFIX="$install_path" ../llvm
ninja -j4
ninja install
