# Post-Build Validation

## Instructions: Target Architecture Check

- Build MuJoCo for Android (e.g., using the provided `docker-compose` file)
- Run the following command to confirm it says Android/ELF aarch64:

```
file build-android/lib/libmujoco.so
```

It would output something like:

```
build-android/lib/libmujoco.so: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, BuildID[sha1]=656481b23c8e005122543fae01f4dd6196265b28, with debug_info, not stripped
```

## Instructions: `libc++_shared.so` Compatibility Check

### From Unity

- Unpack the built APK from Unity project, BEFORE porting in Android build of MuJoCo
- Ensure you can run either `readelf` or `llvm-readelf` (if not, install respective tools)
- Run the following command (from unpacked APK root) and inspect results:

```bash
readelf -V lib/arm64-v8a/libc++_shared.so | head               # note the Build ID/soname
strings lib/arm64-v8a/libc++_shared.so | grep -i 'NDK' | head  # sometimes includes NDK version
```

It would output something like:

```
 ~/G/X/build4  feat/embedded-mujoco  llvm-readelf -V lib/arm64-v8a/libc++_shared.so | head               # note the Build ID/soname
                                     strings lib/arm64-v8a/libc++_shared.so | grep -i 'NDK' | head  # sometimes includes NDK version
Version symbols section '.gnu.version' contains 2498 entries:
 Addr: 000000000000edf0  Offset: 0x00edf0  Link: 4 (.dynsym)
  000:   0 (*local*)       2 (LIBC)          2 (LIBC)          2 (LIBC)
  004:   2 (LIBC)          2 (LIBC)          2 (LIBC)          2 (LIBC)
  008:   2 (LIBC)          2 (LIBC)          2 (LIBC)          2 (LIBC)
  00c:   2 (LIBC)          2 (LIBC)          2 (LIBC)          2 (LIBC)
  010:   2 (LIBC)          2 (LIBC)          2 (LIBC)          2 (LIBC)
  014:   2 (LIBC)          2 (LIBC)          2 (LIBC)          2 (LIBC)
  018:   2 (LIBC)          2 (LIBC)          2 (LIBC)          2 (LIBC)
  01c:   2 (LIBC)          2 (LIBC)          2 (LIBC)          2 (LIBC)
_ZNSt6__ndk16__sortIRNS_6__lessIccEEPcEEvT0_S5_T_
_ZNSt6__ndk16__sortIRNS_6__lessIwwEEPwEEvT0_S5_T_
_ZNSt6__ndk16__sortIRNS_6__lessIaaEEPaEEvT0_S5_T_
_ZNSt6__ndk16__sortIRNS_6__lessIhhEEPhEEvT0_S5_T_
_ZNSt6__ndk16__sortIRNS_6__lessIssEEPsEEvT0_S5_T_
_ZNSt6__ndk16__sortIRNS_6__lessIttEEPtEEvT0_S5_T_
_ZNSt6__ndk16__sortIRNS_6__lessIiiEEPiEEvT0_S5_T_
_ZNSt6__ndk16__sortIRNS_6__lessIjjEEPjEEvT0_S5_T_
_ZNSt6__ndk16__sortIRNS_6__lessIllEEPlEEvT0_S5_T_
_ZNSt6__ndk16__sortIRNS_6__lessImmEEPmEEvT0_S5_T_
```

- Well, turns out this doesn't really include an obvious version string. To check equivalence/compatibility, we can use the soname, Build ID, and file hash:

```bash
readelf -d lib/arm64-v8a/libc++_shared.so | grep SONAME
readelf -n lib/arm64-v8a/libc++_shared.so | grep -A1 Build
sha256sum lib/arm64-v8a/libc++_shared.so
```

Which would output something like:

```
  0x000000000000000e (SONAME)          Library soname: [libc++_shared.so]
    Build ID: b04675a35ad96f8a9dcaa073e3bd31d4536f00ad

4397241b4bd20a8e579bfb41d21107857e12985f6a01ca0c2a5f83380d1270b4  lib/arm64-v8a/libc++_shared.so
```

### From MuJoCo Android Build

- Build MuJoCo for Android (e.g., using the provided `docker-compose` file)
- Run the following command (from `mujoco` root) and inspect results:

```bash
readelf -V build-android/lib/libc++_shared.so | head               # note the Build ID/soname
strings build-android/lib/libc++_shared.so | grep -i 'NDK' | head  # sometimes includes NDK version
```

- Run the soname, Build ID, and file hash check as well:

```bash
readelf -d build-android/lib/libc++_shared.so | grep SONAME
readelf -n build-android/lib/libc++_shared.so | grep -A1 Build
sha256sum build-android/lib/libc++_shared.so
```

Which would output something like:

```
  0x000000000000000e (SONAME)          Library soname: [libc++_shared.so]
    Build ID: ea306390624df9242cca21aeec76a0427683bd72

d523468d62d9b603cb3354294d70d4b2feabf2c3f1e43b0c96c9aabf32813708  build-android/lib/libc++_shared.so
```

- Honestly... even if the two hashes don't match, I think(?) it should be fine??? (We'll have to see!)
