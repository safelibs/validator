#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-xz-memlimit-decompress-zero-default
# @title: xz --memlimit-decompress=0 falls back to the default limit and decodes successfully
# @description: Compresses a small payload then decompresses with --memlimit-decompress=0 (which xz documents as "use defaults") and asserts the round-trip matches the original payload SHA, pinning the documented "0 means default" memlimit semantics in the liblzma-driven decoder.
# @timeout: 60
# @tags: usage, xz, memlimit, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'memlimit-zero-default-payload\n%s\n' "$(date -u +%s)" >"$tmpdir/in.txt"
sha_in=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz -k "$tmpdir/in.txt"
xz -d -k --memlimit-decompress=0 -c "$tmpdir/in.txt.xz" >"$tmpdir/out.txt"
sha_out=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
[[ "$sha_in" == "$sha_out" ]]
