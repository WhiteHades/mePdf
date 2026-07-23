# mePdf

mePdf is an offline-first Android PDF reader and editor with an
application-owned C core. The product is designed around one non-negotiable
rule: a source document is not modified until a separately written destination
has been reopened and verified.

## Status

The repository is in the validation-gate phase. The Android/NDK build and the
first versioned C interface exist; PDF rendering and editing are not implemented
yet. Track verified progress in the [GitHub roadmap](https://github.com/WhiteHades/mePdf/issues/1).

The full feature implementation is intentionally blocked until the license,
storage, content-editing, OCR, fidelity, and hostile-input gates pass. This is a
quality constraint, not a claim that the current scaffold is a finished app.

## Product boundary

The target is a complete mainstream mobile PDF suite:

- Reader-quality tiled viewing, navigation, links, search, selection, themes,
  and reading history.
- Annotations, AcroForms, supported signatures, page organization, encryption,
  repair, and verified transactional commits.
- Offline scanning, OCR, searchable PDFs, conversion, real redaction, and
  constrained existing-content replacement.
- No ads, accounts, paywalls, telemetry, or required backend.

The selected open mobile stack does not honestly guarantee:

- Perfect arbitrary paragraph reflow or layout/font preservation.
- Dynamic XFA or full Acrobat JavaScript compatibility.
- PAdES-LTV across every trust and revocation case.
- Authoritative PDF/A conversion/validation at every level.
- PDF/UA authoring, tagging, or accessibility remediation.
- Linearized output with MuPDF 1.28.
- Reliable fully on-device Office-to-PDF conversion.
- Faithful editing of every malformed, encrypted, signed, or adversarial PDF.

Unsupported documents must be rejected before an operation is applied to the
working copy; limitations will not be hidden behind optimistic UI copy.

## Architecture

The Android shell owns lifecycle, Storage Access Framework integration, durable
jobs, accessibility, and UI. `libmepdf` owns document sessions, rendering,
search, operations, recovery, verification, OCR orchestration, and security.
The JNI interface uses opaque handles and typed results; Kotlin never owns a raw
native pointer.

MuPDF is the selected PDF engine. The release path is
AGPL-3.0-or-later, including the complete corresponding application and build
source. OCR is planned around PP-OCRv6-small through the ONNX Runtime C
interface after its quality gate passes.

## Build

Requirements:

- JDK 21
- Android SDK 36
- Android NDK `28.2.13676358`
- CMake `3.22.1`
- Ninja

Run the host C test and Android build:

```sh
./scripts/verify-native.sh
./gradlew --no-daemon :app:assembleDebug
```

See [build details](docs/building.md) and the
[dependency audit](docs/dependency-licenses.md).

## License

Copyright contributors. Licensed under
AGPL-3.0-or-later. See [LICENSE](LICENSE).
