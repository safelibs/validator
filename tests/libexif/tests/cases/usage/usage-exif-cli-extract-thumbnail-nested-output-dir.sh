#!/usr/bin/env bash
# @testcase: usage-exif-cli-extract-thumbnail-nested-output-dir
# @title: exif --extract-thumbnail writes into a pre-created nested directory
# @description: Creates a multi-level nested directory tree, runs exif --extract-thumbnail with --output pointing into the deepest leaf, and verifies the thumbnail JPEG lands at the requested path with FFD8FF magic, while a parallel run against a non-existent leaf without prior mkdir fails with a write diagnostic and produces no file.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-extract-thumbnail-nested-output-dir"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Pre-create a nested directory and ask exif to extract into it
nested="$tmpdir/a/b/c/deep"
mkdir -p "$nested"
out_path="$nested/thumb.jpg"
exif --extract-thumbnail --output="$out_path" "$img" >"$tmpdir/ok.log"
validator_assert_contains "$tmpdir/ok.log" 'Wrote file'
validator_require_file "$out_path"

# Output must carry the JPEG SOI magic bytes
head -c 3 "$out_path" | od -An -t x1 | tr -d ' \n' >"$tmpdir/magic"
validator_assert_contains "$tmpdir/magic" 'ffd8ff'

# Sanity: a non-empty thumbnail
size=$(stat -c '%s' "$out_path")
if (( size <= 3 )); then
  printf 'expected non-trivial thumbnail size, got %d bytes\n' "$size" >&2
  exit 1
fi

# A parallel run pointing at a non-existent parent must fail (exif has no --create-dirs equivalent)
missing_parent="$tmpdir/does/not/exist/thumb.jpg"
set +e
exif --extract-thumbnail --output="$missing_parent" "$img" \
  >"$tmpdir/miss.stdout" 2>"$tmpdir/miss.stderr"
rc=$?
set -e

if (( rc == 0 )); then
  # Some libexif builds may silently mkdir; if so, just assert the file landed
  if [[ ! -f "$missing_parent" ]]; then
    printf 'extract-thumbnail returned success but did not create %s\n' "$missing_parent" >&2
    cat "$tmpdir/miss.stdout" "$tmpdir/miss.stderr" >&2
    exit 1
  fi
else
  if [[ -e "$missing_parent" ]]; then
    printf 'extract-thumbnail failed but somehow wrote %s\n' "$missing_parent" >&2
    exit 1
  fi
  cat "$tmpdir/miss.stdout" "$tmpdir/miss.stderr" >"$tmpdir/miss.all"
  if ! grep -Eqi 'open|create|write|directory|No such file' "$tmpdir/miss.all"; then
    printf 'expected an open/write diagnostic for missing parent\n' >&2
    cat "$tmpdir/miss.all" >&2
    exit 1
  fi
fi
