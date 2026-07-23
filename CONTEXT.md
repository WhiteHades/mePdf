# mePdf

mePdf is a private, offline-first Android product for reading and safely
modifying PDF documents.

## Language

**Source document**:
The user-selected PDF whose bytes remain unchanged until an explicit,
verified replacement.
_Avoid_: Input file, original file

**Working copy**:
An app-private copy on which operations are applied before commit.
_Avoid_: Temporary PDF, draft file

**Operation**:
A durable, reversible request to change a working copy.
_Avoid_: Edit command, mutation

**Commit**:
The process that writes a new destination, reopens it, and verifies declared
invariants.
_Avoid_: Save, overwrite

**Replacement**:
An explicitly confirmed commit that updates the source document only after a
separate destination has passed verification.
_Avoid_: Save in place, overwrite

**Recovery record**:
Checksummed journal and snapshot state sufficient to resume or safely abandon
an interrupted session.
_Avoid_: Autosave
