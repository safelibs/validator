#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

w="$VALIDATOR_SAMPLE_ROOT/examples/test.webp"; validator_require_file "$w"; printf 'Exif\000\000phase04' >"$tmpdir/exif.bin"; webpmux -set exif "$tmpdir/exif.bin" "$w" -o "$tmpdir/exif.webp"; webpmux -info "$tmpdir/exif.webp" | tee "$tmpdir/m"; grep -i EXIF "$tmpdir/m"
