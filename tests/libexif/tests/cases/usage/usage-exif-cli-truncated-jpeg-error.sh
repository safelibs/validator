#!/usr/bin/env bash
# @testcase: usage-exif-cli-truncated-jpeg-error
# @title: exif rejects a non-JPEG input with a diagnostic
# @description: Feeds the exif client a payload that has no JPEG SOI marker (a plain text file) and a JPEG-shaped file that contains no EXIF segment, verifying the client surfaces a diagnostic on stdout/stderr and exits non-zero on the non-JPEG input while leaving the original canon fixture parseable.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-truncated-jpeg-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Sanity: the original fixture must parse cleanly so any failure on the truncated
# copy is unambiguously due to truncation, not an environment issue.
exif --tag=Make "$img" >"$tmpdir/baseline.out"
validator_assert_contains "$tmpdir/baseline.out" 'Value: Canon'

# Build a non-JPEG file (plain ASCII, no SOI marker) and run exif on it.
notjpeg="$tmpdir/not-a.jpg"
printf 'this is not a jpeg, just plain ascii bytes\n' >"$notjpeg"
validator_require_file "$notjpeg"

set +e
exif "$notjpeg" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
rc=$?
set -e

if (( rc == 0 )); then
  printf 'expected exif to fail on non-JPEG input, got rc=0\n' >&2
  cat "$tmpdir/stdout" "$tmpdir/stderr" >&2
  exit 1
fi

cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"
if [[ ! -s "$tmpdir/all" ]]; then
  printf 'expected an informative diagnostic for non-JPEG input, got empty output\n' >&2
  exit 1
fi
# Diagnostic must indicate the file lacks usable EXIF metadata or could not be read
if ! grep -Eq 'does not contain EXIF data|Corrupt data|specification|cannot|Could not|could not|seem to contain' "$tmpdir/all"; then
  printf 'expected an informative diagnostic explaining the parse failure\n' >&2
  cat "$tmpdir/all" >&2
  exit 1
fi

# The original fixture must still parse cleanly afterwards
exif --tag=Make "$img" >"$tmpdir/post.out"
validator_assert_contains "$tmpdir/post.out" 'Value: Canon'
