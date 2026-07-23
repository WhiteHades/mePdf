# Use an AGPL C core

mePdf uses an application-owned C core behind an opaque JNI interface and
MuPDF under AGPL-3.0-or-later. This keeps document behavior in C and provides
one coherent rendering and editing engine; the complete distributed source and
build system must remain AGPL-compatible.
