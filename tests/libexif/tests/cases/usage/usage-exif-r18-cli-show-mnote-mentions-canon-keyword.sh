#!/usr/bin/env bash
# @testcase: usage-exif-r18-cli-show-mnote-mentions-canon-keyword
# @title: exif --show-mnote on canon fixture mentions a Canon-specific keyword
# @description: Runs exif --show-mnote on the canon fixture and asserts the maker-note dump output contains the literal substring "Canon" (the Canon maker-note parser tags rows with the canon branding), exercising libexif's canon makernote rendering path.
# @timeout: 60
# @tags: usage, exif, makernote, canon, r18
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-mnote "$img" >"$tmpdir/out" 2>"$tmpdir/err"
size=$(wc -c <"$tmpdir/out")
if [[ "$size" -le 0 ]]; then
  echo 'show-mnote produced no output' >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
if ! LC_ALL=C grep -qi 'canon' "$tmpdir/out"; then
  echo 'expected canon keyword in --show-mnote output' >&2
  head -c 4096 "$tmpdir/out" >&2
  exit 1
fi
