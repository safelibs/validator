#!/usr/bin/env bash
# @testcase: usage-tar-r12-transform-rename
# @title: tar --transform rewrites archive member paths via sed expression
# @description: Creates a tar archive with --transform 's,^src/,renamed/,' and verifies the listing shows entries under the renamed/ prefix while the on-disk source remains under src/.
# @timeout: 60
# @tags: usage, tar, transform
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'transform payload\n' >"$tmpdir/src/file.txt"

LC_ALL=C tar --transform='s,^src/,renamed/,' \
  -C "$tmpdir" -cf "$tmpdir/out.tar" src

LC_ALL=C tar -tf "$tmpdir/out.tar" >"$tmpdir/listing.txt"

grep -Fxq 'renamed/file.txt' "$tmpdir/listing.txt"
if grep -Fxq 'src/file.txt' "$tmpdir/listing.txt"; then
  echo 'unexpected un-transformed src/ path in listing' >&2
  cat "$tmpdir/listing.txt" >&2
  exit 1
fi
