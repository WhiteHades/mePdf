# PDF stack research

Research cutoff: 2026-07-23

## Scope boundary

The repository currently defines mePdf as an Android product with an
application-owned C core behind JNI. This note covers that native Android
product only. Android's supported native-code path is Gradle
`externalNativeBuild` with CMake or ndk-build, and its JNI guidance recommends
minimizing boundary crossings and keeping asynchronous UI updates on managed
threads ([Android native-code guide][android-native], [Android JNI
guidance][android-jni]).

## Decision

Use one document engine: **MuPDF 1.28.0**, through its C API, under
AGPL-3.0-or-later. Use **PP-OCRv6-small through the ONNX Runtime C API** for
product OCR, retain MuPDF's Tesseract bridge as a fallback and integration
baseline, and use MuPDF's OpenSSL PKCS#7 helper for basic certificate signing
and verification. Do not add PDFium or QPDF to the initial runtime.

This recommendation keeps the accepted ADR intact and minimizes a dangerous
failure mode: two PDF engines interpreting a working copy, applying operations,
and producing committed output differently.

## Engine comparison

| Candidate | Actual implementation boundary | Relevant capability | Decision |
| --- | --- | --- | --- |
| [MuPDF 1.28.0][mupdf-license] | C implementation and C API; AGPL or commercial | Rendering, text extraction, annotations, AcroForms, page operations, applied redaction, signing/verification hooks, OCR integration, encryption, incremental/full writes | Select as the only PDF engine |
| [PDFium][pdfium-license] | Public `extern "C"` API over a C++ implementation; BSD-style license | Strong rendering, form-fill environment, annotations, and page-object primitives | Reject: weaker language fit and still requires substantial signing, encryption-authoring, redaction, and commit orchestration |
| [QPDF][qpdf-readme] | C++ library with job/C wrappers; Apache-2.0 | Structural transformations, repair, encryption, object streams, and linearization | Reject initially: it does not render and deliberately does not interpret content-stream semantics |

MuPDF's 1.28.0 release is dated 2026-06-26
([release history][mupdf-history]). Its public C headers expose annotation
creation and deletion plus applied redaction
([`annot.h`][mupdf-annot]); field reads/writes, signature digest and certificate
checks, and signing callbacks ([`form.h`][mupdf-form]); page graft/insert/delete
operations and write options including incremental output and encryption
([`document.h`][mupdf-document]); and an OCR device
([`structured-text.h`][mupdf-ocr-header]).

PDFium's public headers expose bitmap rendering, page-object editing,
annotations, form filling, and signature inspection
([`fpdfview.h`][pdfium-view], [`fpdf_edit.h`][pdfium-edit],
[`fpdf_annot.h`][pdfium-annot], [`fpdf_formfill.h`][pdfium-forms],
[`fpdf_signature.h`][pdfium-signature]). Those are useful primitives, but they
do not form a more complete mostly-C editor than the selected MuPDF stack.

QPDF describes itself as a C++ structural, content-preserving transformer and
explicitly says it does not understand PDF content-stream semantics
([upstream README][qpdf-readme], [design notes][qpdf-design]). It becomes worth
reconsidering only if linearized output is a release gate: MuPDF 1.28 retains a
write-option field but its writer rejects linearisation
([`pdf-write.c`][mupdf-writer]), while QPDF documents linearized writing.

## Capability plan

### Render, navigate, search, and select

Use MuPDF pages and display lists for tiled rendering. A single worker owns
each open document and produces immutable display lists; render workers use
cloned contexts. MuPDF's current threading example requires separate contexts,
forbids simultaneous use of one document, and demonstrates rendering shared
display lists on worker threads ([MuPDF threading example][mupdf-threading]).

Build the first reader around:

1. viewport tiles and a bounded cache;
2. outlines and links;
3. structured-text extraction, search, and selection geometry;
4. reading-position persistence outside the PDF;
5. cancellable background rendering through MuPDF cookies.

### Annotations and forms

Implement annotations directly with MuPDF's typed annotation API. The public
header covers annotation enumeration, creation, deletion, appearance updates,
and redaction application ([`annot.h`][mupdf-annot]). Implement AcroForm
inspection, value changes, appearance regeneration, and signature widgets with
the form API ([`form.h`][mupdf-form]).

Round-trip fixtures are mandatory. Every supported annotation and field type
must be committed to a separate destination, reopened in a fresh context, and
compared in mePdf, Acrobat Reader, and a browser viewer before it is claimed
as supported.

### Page and content editing

Ship page organization first: merge/graft, insert, delete, reorder, rotate,
crop, extract, split, and blank-page creation. These operations map to public
MuPDF document/page primitives ([`document.h`][mupdf-document]).

Treat arbitrary existing paragraph editing as unsupported. PDF is a static
page-description format whose imaging model describes text and graphics
painting ([ISO 32000-2][pdf-spec]); it does not retain a word processor's
paragraph and reflow model. MuPDF supplies low-level content/resource
operations, not a high-level "replace paragraph while preserving layout" API.
The honest first content-editing boundary is:

- add text and image overlays;
- replace an image only after resolving shared resources;
- remove selected objects only when the operation can be verified;
- apply true redaction and sanitize residual metadata;
- reject documents whose fonts, shared XObjects, patterns, masks, clipping, or
  transforms cannot be preserved safely.

### OCR

Use PP-OCRv6-small as the product default behind ONNX Runtime's C API. Paddle's
official PP-OCRv6 documentation defines small and tiny detector/recognizer
tiers, and its current Android guide documents ONNX Runtime 1.21.1, OpenCV
4.5.3, `minSdk 26`, and v6-small/v6-tiny model integration
([PP-OCRv6 documentation][ppocr-v6], [Android demo][ppocr-android],
[ONNX Runtime C guide][onnx-c]). Benchmark the small tier on the supported
device floor before freezing it; retain tiny as a storage/memory fallback only
if the measured quality loss is acceptable.

The selected v6-small recognizer supports 50 languages. Paddle reports detector
Hmean 84.1 and recognizer weighted accuracy 81.3 on separate private
multi-scenario benchmarks; neither value is an end-to-end app accuracy result
([PP-OCRv6 documentation][ppocr-v6]). Do not quantize first. Establish golden
output parity with the official Android demo, then evaluate FP16 or INT8 against
a fixed corpus.

Keep MuPDF's Tesseract OCR device as a fallback and searchable-PDF integration
baseline. It bridges to Tesseract through a C++ implementation
([OCR header][mupdf-ocr-header], [MuPDF Tesseract bridge][mupdf-tessocr]).
Tesseract exposes a C API but is predominantly C++ and depends on Leptonica
([Tesseract repository][tesseract], [`capi.h`][tesseract-c-api]). ONNX Runtime
also exposes a C API over a native runtime. The application-owned orchestration
remains C, but neither OCR path makes the transitive dependency graph all-C.

ONNX Runtime only executes tensors. The application-owned C layer must perform
normalization and resizing, detector decoding, box filtering and ordering, crop
generation, recognition input preparation, CTC decoding, dictionary selection,
and searchable-text geometry. For initial parity, isolate the required OpenCV
contour, polygon-expansion, and perspective-warp operations behind a narrow
private C ABI; this remains a disclosed C++ dependency.

Keep OCR as a geometry-producing pipeline:

1. render the page at a controlled DPI;
2. recognize text and retain word/line boxes and confidence;
3. map pixel boxes back into PDF coordinates;
4. write an invisible searchable text layer;
5. reopen, search known strings, and render-diff the page;
6. load the bundled v6-small model, or a versioned optional script pack.

Do not represent OCR success with extracted text alone. Searchability and
coordinate alignment are part of the feature.

The official PaddlePaddle Hugging Face model cards for the selected v6-small
detector and recognizer each declare Apache-2.0 and include a repository license
([detector model card][ppocr-det-model], [recognizer model card][ppocr-rec-model]).
This supports redistribution of those exact ONNX weights and recognition
configuration subject to Apache notice/license obligations. Pin the downloaded
files by SHA-256 and include their license in the shipped notices. Do not infer
that license for other Paddle model packs: verify every optional pack's own
first-party model card before bundling it. ONNX Runtime itself is MIT-licensed
([ONNX Runtime license][onnx-license]).

### Digital signatures and encryption

Keep drawn signatures and certificate-backed digital signatures as separate
features. MuPDF's form API provides signer/verifier abstractions and digest and
certificate checks, while the official `mutool sign` workflow signs with a PFX
certificate ([`form.h`][mupdf-form], [MuPDF tools guide][mupdf-tools]). MuPDF
also ships a C OpenSSL PKCS#7 helper
([`pkcs7-openssl.h`][mupdf-pkcs7]).

The first certificate-signing scope should be:

- sign an existing empty signature field with a user-selected PFX;
- create a signature field only after interoperable fixtures pass;
- report cryptographic integrity separately from certificate trust;
- report modifications after signing;
- never claim revocation checking, trusted identity, timestamp authority,
  PAdES-LTV, or long-term validation until each is explicitly implemented and
  tested.

For encryption, expose AES-256 for newly protected output and preserve or
remove existing encryption through MuPDF write options. Continue reading old
RC4/AES variants for compatibility, but do not offer obsolete RC4 for new
files. PDF permission flags are interoperability hints, not a security
boundary; possession of a decryption key gives the application access to
plaintext.

### Commit integrity

All of these features remain subordinate to the repository's existing commit
ADR:

1. apply operations to an app-private working copy;
2. write a separate destination;
3. close it and reopen it in a fresh parser context;
4. verify page count, encryption state, expected operations, form/signature
   state, searchable OCR text, and representative renders;
5. default to keeping the committed copy;
6. allow replacement only after explicit confirmation and source-identity
   revalidation.

Incremental writing is useful for signatures and small changes, but it does not
replace the separate-destination and reopen verification rule.

## Release gates created by this research

1. Confirm AGPL compatibility for the complete distributed dependency graph
   and publish corresponding source/build instructions; MuPDF's official
   license requires AGPL compliance or a commercial license
   ([MuPDF license][mupdf-license]).
2. Prove single-document serialization and display-list worker rendering under
   ThreadSanitizer where supported.
3. Establish a hostile/corrupt PDF corpus and fuzz every C entry point that
   accepts external bytes.
4. Round-trip annotations, AcroForms, redaction, encryption, and signatures
   through independent viewers.
5. Measure OCR accuracy, geometry, latency, memory, and output size per selected
   language pack.
6. Record SHA-256, source URL, version, and first-party redistribution license
   for every bundled OCR model and dictionary; do not ship an optional pack
   whose terms are unresolved.
7. Run native and instrumented tests on the minimum supported Android API and
   every shipped ABI, then smoke-test the signed release bundle on real devices.

[android-native]: https://developer.android.com/studio/projects/add-native-code
[android-jni]: https://developer.android.com/training/articles/perf-jni
[mupdf-annot]: https://github.com/ArtifexSoftware/mupdf/blob/1.28.0/include/mupdf/pdf/annot.h
[mupdf-document]: https://github.com/ArtifexSoftware/mupdf/blob/1.28.0/include/mupdf/pdf/document.h
[mupdf-form]: https://github.com/ArtifexSoftware/mupdf/blob/1.28.0/include/mupdf/pdf/form.h
[mupdf-history]: https://mupdf.com/releases/history
[mupdf-license]: https://mupdf.readthedocs.io/en/1.28.0/license.html
[mupdf-ocr-header]: https://github.com/ArtifexSoftware/mupdf/blob/1.28.0/include/mupdf/fitz/structured-text.h
[mupdf-pkcs7]: https://github.com/ArtifexSoftware/mupdf/blob/1.28.0/include/mupdf/helpers/pkcs7-openssl.h
[mupdf-tessocr]: https://github.com/ArtifexSoftware/mupdf/blob/1.28.0/source/fitz/tessocr.cpp
[mupdf-threading]: https://mupdf.readthedocs.io/en/1.28.0/cookbook/c/multi-threaded.html
[mupdf-tools]: https://mupdf.readthedocs.io/en/1.28.0/tools/mutool-sign.html
[mupdf-writer]: https://github.com/ArtifexSoftware/mupdf/blob/1.28.0/source/pdf/pdf-write.c
[onnx-c]: https://onnxruntime.ai/docs/get-started/with-c.html
[onnx-license]: https://github.com/microsoft/onnxruntime/blob/main/LICENSE
[pdf-spec]: https://www.iso.org/standard/75839.html
[pdfium-annot]: https://pdfium.googlesource.com/pdfium/+/main/public/fpdf_annot.h
[pdfium-edit]: https://pdfium.googlesource.com/pdfium/+/main/public/fpdf_edit.h
[pdfium-forms]: https://pdfium.googlesource.com/pdfium/+/main/public/fpdf_formfill.h
[pdfium-license]: https://pdfium.googlesource.com/pdfium/+/main/LICENSE
[pdfium-signature]: https://pdfium.googlesource.com/pdfium/+/main/public/fpdf_signature.h
[pdfium-view]: https://pdfium.googlesource.com/pdfium/+/main/public/fpdfview.h
[qpdf-design]: https://qpdf.readthedocs.io/en/stable/design.html
[qpdf-readme]: https://github.com/qpdf/qpdf
[ppocr-android]: https://github.com/PaddlePaddle/PaddleOCR/blob/main/docs/version3.x/inference_deployment/cross_platform/android_deployment.en.md
[ppocr-det-model]: https://huggingface.co/PaddlePaddle/PP-OCRv6_small_det_onnx
[ppocr-rec-model]: https://huggingface.co/PaddlePaddle/PP-OCRv6_small_rec_onnx
[ppocr-v6]: https://github.com/PaddlePaddle/PaddleOCR/blob/main/docs/version3.x/algorithm/PP-OCRv6/PP-OCRv6.en.md
[tesseract]: https://github.com/tesseract-ocr/tesseract
[tesseract-c-api]: https://github.com/tesseract-ocr/tesseract/blob/5.5.2/include/tesseract/capi.h
