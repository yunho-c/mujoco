## MuJoCo Unity Android/Quest build setup

### Goals
- Produce an ARM64 `libmujoco.so` for Unity Android/Quest (Meta Quest 3).
- Keep tooling reproducible with Docker Compose; outline a future GitHub Actions workflow (separate from existing `.github/workflows/build.yml`).

### Docker Compose skeleton
Use an Android SDK/NDK image with CMake/Ninja (example uses NDK r26c, CMake 3.22+):
```yaml
services:
  mujoco-android:
    image: ghcr.io/cirruslabs/android-sdk:36
    environment:
      ANDROID_HOME: /opt/android-sdk
      ANDROID_NDK_HOME: /opt/android-sdk/ndk/26.2.11394342
    volumes:
      - .:/workspace
    working_dir: /workspace
    command: >
      bash -lc "
        cmake -S . -B build-android \
          -G Ninja \
          -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
          -DANDROID_ABI=arm64-v8a \
          -DANDROID_PLATFORM=android-24 \
          -DMUJOCO_ENABLE_AVX=OFF \
          -DMUJOCO_ENABLE_AVX_INTRINSICS=OFF \
          -DMUJOCO_BUILD_EXAMPLES=OFF \
          -DMUJOCO_BUILD_TESTS=OFF \
          -DMUJOCO_USE_FILAMENT=OFF \
          -DBUILD_SHARED_LIBS=ON
        cmake --build build-android --target mujoco
      "
```
Notes:
- If the image lacks CMake/Ninja, install via `sdkmanager "cmake;3.22.1" "ndk;26.2.11394342"` or `apt-get install cmake ninja-build`.
- If NDK warnings fail the build, relax `-Werror`: add `-DCMAKE_C_FLAGS=-Wno-error -DCMAKE_CXX_FLAGS=-Wno-error`.

### Local usage flow
1) Run: `docker-compose run --rm mujoco-android`.
2) Copy the built `build-android/libmujoco.so` (rename if needed) into your Unity project/package at `Assets/Plugins/Android/arm64-v8a/libmujoco.so`.
3) In Unity, set Player Settings → Android → Target Architectures = ARM64; build and deploy to Quest. Validate MJCF load/step on-device.

### Future GitHub Actions idea (separate workflow)
- New workflow file (not the current `.github/workflows/build.yml`) that:
  - Uses `actions/setup-java` + `android-actions/setup-android` (or manual `sdkmanager`) + `nttld/setup-ndk@v1`.
  - Caches `$ANDROID_HOME/.android` and the NDK path.
  - Runs the same CMake/Ninja commands as above and uploads `libmujoco.so` as an artifact.
- Start with a single target (`ANDROID_PLATFORM=android-24`, `arm64-v8a`) to keep runtime short; expand to matrices later if needed.
