#!/bin/bash
set -e

# Optional: Print commands for debugging
set -x

rm -rf build-android

# Standard Bash variables (single $) and cleaner formatting
cmake -S . -B build-android -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DANDROID_STL=c++_shared \
  -DMUJOCO_ENABLE_AVX=OFF \
  -DMUJOCO_ENABLE_AVX_INTRINSICS=OFF \
  -DMUJOCO_BUILD_EXAMPLES=OFF \
  -DMUJOCO_BUILD_TESTS=OFF \
  -DMUJOCO_BUILD_SIMULATE=OFF \
  -DMUJOCO_USE_FILAMENT=OFF \
  -DMUJOCO_BUILD_GLFW=OFF \
  -DBUILD_SHARED_LIBS=ON

cmake --build build-android --target mujoco

# Copy libc++_shared.so to the build directory
cp "${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" build-android/lib/
