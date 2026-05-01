#!/usr/bin/env bash
# @testcase: usage-exif-cli-show-mnote-ids-hex-prefix
# @title: exif --show-mnote --ids prefixes rows with 0x0001 hex tag ids
# @description: Runs exif --show-mnote --ids on the canon fixture and confirms the maker-note dump still announces 96 entries with MakerNote contains 96 values and renders Canon mnote rows using hex tag ids prefixed with 0x rather than the symbolic Macro Mode label, with the very first 0x0001 row decoded as the Normal value and a Superfine Quality row also reachable.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-show-mnote-ids-hex-prefix"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-mnote --ids "$img" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'MakerNote contains 96 values'
validator_assert_contains "$tmpdir/out" '0x0001|Normal'
validator_assert_contains "$tmpdir/out" '0x0001|Superfine'

# --ids must replace the symbolic Macro Mode header with the hex form
if grep -Fq -- 'Macro Mode|' "$tmpdir/out"; then
  printf '--ids unexpectedly emitted symbolic Macro Mode label\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
