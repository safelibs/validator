#!/usr/bin/env bash
# @testcase: usage-exif-cli-show-mnote-machine-readable-tabs
# @title: exif --show-mnote --machine-readable emits tab-separated rows
# @description: Runs exif --show-mnote --machine-readable on the canon fixture and verifies the maker-note dump uses the canonical name<TAB>value layout with no plus-or-pipe separator characters and includes the Canon-specific Macro Mode, Quality, Flash Mode, and Image Size lines reachable through the libexif Canon mnote backend.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-show-mnote-machine-readable-tabs"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --show-mnote --machine-readable "$img" >"$tmpdir/out"

# Canonical Canon mnote rows
validator_assert_contains "$tmpdir/out" 'Macro Mode'
validator_assert_contains "$tmpdir/out" 'Quality'
validator_assert_contains "$tmpdir/out" 'Flash Mode'
validator_assert_contains "$tmpdir/out" 'Image Size'

# A specific tab-separated row must be present byte-exact
expected_tab=$(printf 'Macro Mode\tNormal\n')
if ! grep -Fq -- "$expected_tab" "$tmpdir/out"; then
  printf 'expected exact tab-separated row Macro Mode<TAB>Normal\n' >&2
  od -An -c "$tmpdir/out" | head -20 >&2
  exit 1
fi

# Machine-readable must not produce the pretty 'MakerNote contains' header
if grep -Fq -- 'MakerNote contains' "$tmpdir/out"; then
  printf 'machine-readable mnote unexpectedly emitted pretty header\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi

# And there must be no pipe-table separators
if grep -Fq -- '|' "$tmpdir/out"; then
  printf 'machine-readable mnote unexpectedly contained pipe characters\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
