# Dependency license audit

This file records build and distribution inputs for the AGPL compatibility
gate. A planned dependency is not part of a distributed artifact until the
build actually consumes it.

## Current inputs

| Input | Pin | License | Distribution role | Status |
| --- | --- | --- | --- | --- |
| mePdf source | repository revision | AGPL-3.0-or-later | Application source and native library | Included |
| Gradle | 9.1.0 + wrapper SHA-256 | Apache-2.0 | Build tool; not packaged | Verified pin |
| Android Gradle Plugin | 9.0.1 | Apache-2.0 | Build plugin; not packaged | Verified pin |
| Android SDK | API 36 | Android SDK license | Build platform/framework interface | Local prerequisite |
| Android NDK | 28.2.13676358 | Android SDK license and component notices | Native toolchain | Local prerequisite |
| CMake | 3.22.1 | BSD-3-Clause | Native build tool; not packaged | Local prerequisite |

The current APK contains only project code plus Android platform/native runtime
references. It has no network, telemetry, advertising, account, payment, PDF,
OCR, or model dependency.

## Planned, not yet included

| Input | Planned pin | Expected license path | Gate requirement |
| --- | --- | --- | --- |
| MuPDF | 1.28.0 | AGPL-3.0-or-later | Build from pinned corresponding source; retain notices and publish complete source/build scripts |
| ONNX Runtime | To be pinned | MIT | Audit Android artifact contents and third-party notices before inclusion |
| PP-OCRv6-small models | To be pinned by checksum | Unresolved | Confirm model-specific redistribution terms from primary sources before inclusion |
| OpenCV core/imgproc helper | To be pinned if required | Apache-2.0 | Keep the private C interface narrow and disclose the C++ implementation |

No planned dependency may enter the build while its version, source, license,
notices, and artifact contents are unresolved.

## Remaining gate evidence

- Resolve and document model-specific redistribution terms.
- Generate a machine-readable SBOM from the actual release artifact.
- Record native transitive libraries and Maven artifact contents.
- Rebuild signed release artifacts in clean environments and compare hashes.
- Publish exact corresponding source and third-party notices for every release.
