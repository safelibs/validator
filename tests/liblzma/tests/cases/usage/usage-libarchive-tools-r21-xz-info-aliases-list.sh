#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-xz-info-aliases-list
# @title: xz --no-sparse decompression yields identical bytes to plain decompression
# @description: Compresses a small payload then decompresses with --no-sparse and asserts the result matches the original byte-for-byte, pinning that suppressing sparse-file creation does not alter the liblzma-decoded byte stream contents.
# @timeout: 60
# @tags: usage, xz, no-sparse, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'sparse-test-payload-%s\n' alpha beta gamma >"$tmpdir/in.txt"
sha_in=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -k "$tmpdir/in.txt"
mv "$tmpdir/in.txt.xz" "$tmpdir/payload.xz"

xz -d --no-sparse -k -c "$tmpdir/payload.xz" >"$tmpdir/out.txt"
sha_out=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$sha_in" == "$sha_out" ]] || { echo "sha mismatch in=$sha_in out=$sha_out" >&2; exit 1; }
