#!/usr/bin/env bash
# @testcase: usage-tar-batch12-numeric-owner-uid-zero-roundtrip
# @title: tar --numeric-owner --owner=0 --group=0 roundtrip
# @description: Creates a tar archive with --numeric-owner --owner=0 --group=0 and verifies tar -tvf shows uid 0 / gid 0 for the entry.
# @timeout: 60
# @tags: usage, tar
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'tar uid 0\n' >"$tmpdir/src/file.txt"

tar --numeric-owner --owner=0 --group=0 \
    -C "$tmpdir/src" -cf "$tmpdir/out.tar" file.txt

tar --numeric-owner -tvf "$tmpdir/out.tar" >"$tmpdir/listing.txt"
# Listing format: -rw-r--r-- 0/0   <size> <date> <time> file.txt
grep -E '^[-rwx]+[[:space:]]+0/0[[:space:]]' "$tmpdir/listing.txt" >/dev/null
