## MuJoCo Unity plugin on Android / Quest 3 (ARM64) – feasibility

**Current state**
- Unity package ships only C# bindings; no native binaries in `unity/` (see `unity/Runtime/Bindings/MjBindings.cs` with `DllImport("mujoco")` and `find unity ...` returning no `.so`/`.aar`).
- Docs list install steps only for macOS/Linux/Windows (`doc/unity.rst`), implying official binaries are desktop-only; no Android guidance or release artifacts.
- The CMake build targets desktop/WASM; defaults assume AVX (`cmake/MujocoOptions.cmake`) which is x86-only. No Android toolchain presets.

**What would be required to run on Quest (Unity Android/IL2CPP, ARM64)**
- Produce an ARM64 `libmujoco.so` with the Android NDK (e.g., `cmake -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24 -DMUJOCO_ENABLE_AVX=OFF -DMUJOCO_BUILD_EXAMPLES=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_USE_FILAMENT=OFF .. && ninja`). Expect to also disable AVX intrinsics and possibly drop `-Werror` if the NDK surfaces warnings.
- Package the result under the Unity project at `Assets/Plugins/Android/arm64-v8a/libmujoco.so` (or inside the package directory) so the `DllImport("mujoco")` resolves on device builds.
- Keep IL2CPP/backend settings at ARM64 (Quest 3 requirement). No renderer is needed from MuJoCo—Unity handles rendering—so build just the core physics library.

**Risks / gaps**
- Unvalidated platform: the repo ships no Android build, so you’d be the first adopter. Build fixes may be needed if MuJoCo uses syscalls/headers that differ on Bionic/Android (e.g., `mmap`, `clock_gettime`), though they are typically available.
- Performance: disabling AVX removes SIMD speedups; Quest CPU is modest, so complex scenes may not reach real-time.
- Packaging: Unity’s package manager only auto-copies desktop native libs; Android requires manual placement under `Plugins/Android`. Need to verify Gradle packaging and `android:extractNativeLibs` defaults work for Quest.
- Testing: no automated coverage for ARM/Android; must verify load, step, and teardown on device. Also validate MJCF import paths on Android (file I/O, streaming assets).

**Feasibility judgment**
- Technically possible but not supported out-of-the-box. Expect a custom NDK build of MuJoCo plus Unity packaging work and on-device validation. No blockers are visible in the Unity C# layer; the main work is producing and shipping a stable ARM64 `libmujoco.so` and confirming runtime performance on Quest hardware.
