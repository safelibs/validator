#!/usr/bin/env bash
# @testcase: usage-gzip-recursive-dir
# @title: gzip recursive directory compress
# @description: Compresses every regular file under a directory tree with gzip -r and verifies all members are replaced by .gz files that decompress back to the original payloads.
# @timeout: 180
# @tags: usage, gzip, archive
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-recursive-dir"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree/sub"
printf 'top-level alpha\n' >"$tmpdir/tree/alpha.txt"
printf 'top-level beta\n' >"$tmpdir/tree/beta.txt"
printf 'nested gamma payload\n' >"$tmpdir/tree/sub/gamma.txt"

# Capture original sha256 sums for later comparison.
( cd "$tmpdir/tree" && find . -type f | sort | xargs sha256sum ) >"$tmpdir/orig.sums"

gzip -r "$tmpdir/tree"

# All originals must be replaced by .gz files.
for orig in alpha.txt beta.txt sub/gamma.txt; do
  if [[ -e "$tmpdir/tree/$orig" ]]; then
    printf 'original %s should have been replaced\n' "$orig" >&2
    exit 1
  fi
  if [[ ! -f "$tmpdir/tree/$orig.gz" ]]; then
    printf 'expected gzip output %s.gz not found\n' "$orig" >&2
    exit 1
  fi
done

gz_count=$(find "$tmpdir/tree" -type f -name '*.gz' | wc -l)
if (( gz_count != 3 )); then
  printf 'expected 3 .gz files, got %s\n' "$gz_count" >&2
  exit 1
fi

# Decompress in place and verify checksums match the originals.
gzip -dr "$tmpdir/tree"
( cd "$tmpdir/tree" && find . -type f | sort | xargs sha256sum ) >"$tmpdir/post.sums"

if ! diff -u "$tmpdir/orig.sums" "$tmpdir/post.sums" >"$tmpdir/diff"; then
  printf 'recursive gzip roundtrip altered file checksums:\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi
