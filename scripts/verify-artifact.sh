#!/usr/bin/env sh

set -eu

apk=app/build/outputs/apk/debug/app-debug.apk
sbom=build/reports/cyclonedx/bom.json
manifest=build/reports/artifact-manifest.txt

test -s "$apk"
test -s "$sbom"

jq -e '
  .specVersion == "1.6" and
  .metadata.component.group == "org.mepdf" and
  .metadata.component.version == "0.1.0" and
  any(.components[]; .name == "kotlin-stdlib" and .version == "2.2.10") and
  any(.components[]; .name == "annotations" and .version == "13.0")
' "$sbom" >/dev/null

{
    git rev-parse HEAD | sed 's/^/source_commit /'
    sha256sum "$apk" "$sbom"
    unzip -p "$apk" lib/arm64-v8a/libmepdf.so |
        sha256sum | sed 's|  -$|  lib/arm64-v8a/libmepdf.so|'
    unzip -p "$apk" lib/x86_64/libmepdf.so |
        sha256sum | sed 's|  -$|  lib/x86_64/libmepdf.so|'
} >"$manifest"

test -s "$manifest"
cat "$manifest"
