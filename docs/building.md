# Building mePdf

## Pinned toolchain

| Input | Version |
| --- | --- |
| Gradle | 9.1.0 |
| Android Gradle Plugin | 9.0.1 |
| Java toolchain | 21 |
| Android compile/target SDK | 36 |
| Android minimum SDK | 26 |
| Android NDK | 28.2.13676358 |
| CMake | 3.22.1 |
| C language | C17 |

The Gradle wrapper validates its downloaded distribution with the SHA-256 in
`gradle/wrapper/gradle-wrapper.properties`.

Generate the aggregate CycloneDX SBOM with:

```sh
./gradlew --no-daemon cyclonedxBom
```

The JSON and XML documents are written under `build/reports/cyclonedx/`.

## Host native verification

Keep task artifacts inside the repository and remove them when finished:

```sh
cmake -S . -B .tmp/native-build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build .tmp/native-build
ctest --test-dir .tmp/native-build --output-on-failure
rm -rf .tmp/native-build
```

## Android debug build

Set `ANDROID_HOME` to the installed SDK and use JDK 21:

```sh
./gradlew --no-daemon :app:assembleDebug
```

The app intentionally does not request network access. Both `arm64-v8a` and
`x86_64` native libraries are built so physical ARM64 devices and x86_64
emulators can exercise the same C interface. Flexible page sizes are enabled
for Android 16 KB page-size compatibility.

## Current reproducibility boundary

The build inputs are pinned, but a bit-for-bit reproducible signed release has
not been proven. Debug signing and Android packaging metadata are outside the
current evidence. Issue #2 remains open until release artifacts are rebuilt in
clean environments, compared, and matched to an SBOM and exact source revision.
