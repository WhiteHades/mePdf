# Building mePdf

## Declared toolchain

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
`gradle/wrapper/gradle-wrapper.properties`. Resolved plugin and Maven artifact
bytes are not yet locked; issue #2 remains open on that evidence.

Generate the aggregate CycloneDX SBOM with:

```sh
./gradlew --no-daemon cyclonedxBom
```

The JSON and XML documents are written under `build/reports/cyclonedx/`.

## Host native verification

Keep task artifacts inside the repository and remove them when finished:

```sh
./scripts/verify-native.sh
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

The current unsigned APK reproduced byte-for-byte across two clean builds in
one local environment. CI actions and Java are pinned, but the GitHub runner
image and its host CMake/Ninja packages are not immutable. Cross-environment
reproducibility and a reproducible signed release have not been proven. Issue
#2 remains open until release artifacts are rebuilt in independent immutable
environments, compared, and matched to an SBOM and exact source revision.
