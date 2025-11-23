# Android Build Fixes

This document details the changes made to fix the Android build process using Docker.

## 1. Docker Configuration

### `docker/docker-compose.yml`
*   **Path Fix**: Updated the `command` to point to `docker/build_android.sh` instead of `./build_android.sh`, as the working directory is the project root.
*   **Platform Architecture**: Added `platform: linux/amd64`.
    *   **Reason**: The Android NDK toolchain binaries provided in the Docker image are built for x86_64 Linux. When running on an ARM host (like Apple Silicon), Docker might default to an ARM64 container environment. Attempting to run the x86_64 NDK binaries inside an ARM64 container fails (e.g., missing dynamic linker errors).
    *   **Impact on Target**: This **does not** affect the target architecture of the built library. The build script explicitly configures CMake for cross-compilation (`-DANDROID_ABI=arm64-v8a`), ensuring the output is correctly built for Android ARM devices, regardless of the host container's architecture.

## 2. Build Script (`docker/build_android.sh`)

*   **Executable Permissions**: The script was made executable (`chmod +x`).
*   **Disabled Dependencies**:
    *   `-DMUJOCO_BUILD_SIMULATE=OFF`: The simulation library depends on GLFW and OpenGL visualization, which requires system libraries (X11, Wayland) not present or relevant in the Android build container.
    *   `-DMUJOCO_BUILD_GLFW=OFF`: Explicitly disabled GLFW to prevent CMake from attempting to find or fetch it, avoiding configuration errors related to missing X11 headers.
*   **Runtime Library**:
    *   Added a step to copy `libc++_shared.so` from the NDK to the build output directory (`build-android/lib/`). This shared library is required at runtime by the Android application (e.g., Unity) to support C++ standard library features used by MuJoCo.

## 3. Source Code (`src/engine/engine_util_errmem.c`)

*   **Memory Allocation**:
    *   Replaced `aligned_alloc` with `memalign` for Android builds. `aligned_alloc` is a C11 feature that may not be fully supported or exposed in the specific NDK environment/API level being used.
    *   Code change:
        ```c
        #if defined(ANDROID) || defined(__ANDROID__)
          return memalign(align, size);
        #elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
          return aligned_alloc(align, size);
        #endif
        ```
*   **Time Functions**:
    *   Enabled `localtime_r` for Android. The standard C library check was failing to detect a thread-safe `localtime` alternative.
    *   Code change:
        ```c
        #if defined(_POSIX_C_SOURCE) || ... || defined(ANDROID) || defined(__ANDROID__)
            localtime_r(&rawtime, &timeinfo);
