#!/usr/bin/env bash
# @testcase: usage-tar-r18-gzip-z-flag-roundtrip
# @title: tar -czf and tar -xzf round-trip a directory tree through gzip
# @description: Stages two files under one directory, creates a gzipped tar with -czf, extracts it into a fresh location with -xzf, and asserts both files are restored with matching content — locking in libc-backed tar+gzip stream handling on noble.
# @timeout: 60
# @tags: usage, tar, gzip, roundtrip, r18
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'alpha-data\n' >"$tmpdir/src/a.txt"
printf 'bravo-data\n' >"$tmpdir/src/b.txt"

cd "$tmpdir"
tar -czf out.tar.gz src
mkdir -p "$tmpdir/extracted"
tar -xzf out.tar.gz -C "$tmpdir/extracted"

[[ -f "$tmpdir/extracted/src/a.txt" ]] || { printf 'missing a.txt after extract\n' >&2; exit 1; }
[[ -f "$tmpdir/extracted/src/b.txt" ]] || { printf 'missing b.txt after extract\n' >&2; exit 1; }

diff "$tmpdir/src/a.txt" "$tmpdir/extracted/src/a.txt"
diff "$tmpdir/src/b.txt" "$tmpdir/extracted/src/b.txt"
