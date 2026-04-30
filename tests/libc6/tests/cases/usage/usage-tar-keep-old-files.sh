#!/usr/bin/env bash
# @testcase: usage-tar-keep-old-files
# @title: tar keep-old-files refuses overwrite
# @description: Extracts a tar archive over an existing file with --keep-old-files and verifies the original payload is preserved.
# @timeout: 180
# @tags: usage, archive
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-tar-keep-old-files"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/outdir"
printf 'archived payload\n' >"$tmpdir/src/file.txt"
tar -C "$tmpdir/src" -cf "$tmpdir/archive.tar" file.txt

# pre-populate destination with a different payload
printf 'preexisting payload\n' >"$tmpdir/outdir/file.txt"

# extraction must refuse to overwrite the existing file; tar exits non-zero
status=0
tar -C "$tmpdir/outdir" --keep-old-files -xf "$tmpdir/archive.tar" 2>"$tmpdir/err" || status=$?
[[ "$status" -ne 0 ]] || {
  printf 'expected tar --keep-old-files to fail when the destination exists\n' >&2
  exit 1
}

validator_assert_contains "$tmpdir/outdir/file.txt" 'preexisting payload'
if grep -Fq 'archived payload' "$tmpdir/outdir/file.txt"; then
  printf 'destination was overwritten despite --keep-old-files\n' >&2
  exit 1
fi
