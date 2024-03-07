#!/usr/bin/env/bash

test -d out || mkdir -p out
export install_path=./out

git clone https://android.googlesource.com/platform/external/toolchain-utils --depth=1 --recursive
git clone https://android.googlesource.com/toolchain/binutils --depth=1 --recursive
git clone https://android.googlesource.com/toolchain/llvm_android --depth=1 --recursive
git clone https://android.googlesource.com/toolchain/llvm-project --depth=1 --recursive

cd toolchain-utils
git checkout $util_hash
cd ..

cd llvm-project
git checkout $version_hash
cd ..

cd llvm_android
git checkout $android_hash
cd ..

export versionss=$(echo $versions | sed 's/r\([0-9]\+\)[a-zA-Z]\?/\1/g')

python3 toolchain-utils/llvm_tools/patch_manager.py --svn_version $versions --patch_metadata_file llvm_android/patches/PATCHES.json --filesdir_path llvm_android/patches --src_path llvm-project --use_src_head --failure_mode fail

cd llvm-project
mkdir build
cd build
cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" \
        -DLLVM_TARGETS_TO_BUILD="AArch64;ARM" \
        -DLLVM_BUILD_TESTS=OFF \
        -DLLVM_ENABLE_WARNINGS=OFF \
        -DCMAKE_INSTALL_PREFIX=$install_path ../llvm
ninja -j4
ninja install
