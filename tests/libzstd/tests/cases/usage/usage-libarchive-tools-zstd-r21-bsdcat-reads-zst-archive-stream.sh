#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r21-bsdcat-reads-zst-archive-stream
# @title: bsdcat reads a tar.zst archive and emits the concatenated member bytes
# @description: Creates a tar.zst archive containing two small text members and runs bsdcat against it, asserting the streamed output contains the bytes from both members — pinning libarchive's bsdcat zst reader on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, archive, bsdcat, zstd, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src=$tmpdir/src
mkdir -p "$src"
printf 'first-r21\n' >"$src/a.txt"
printf 'second-r21\n' >"$src/b.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir" src

bsdcat "$tmpdir/a.tar.zst" >"$tmpdir/out.bytes"
grep -Fq 'first-r21' "$tmpdir/out.bytes" || { echo "expected first-r21 in bsdcat output" >&2; cat "$tmpdir/out.bytes" >&2; exit 1; }
grep -Fq 'second-r21' "$tmpdir/out.bytes" || { echo "expected second-r21 in bsdcat output" >&2; cat "$tmpdir/out.bytes" >&2; exit 1; }
