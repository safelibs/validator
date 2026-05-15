#!/usr/bin/env bash
# @testcase: usage-gio-r19-save-stdin-writes-file-payload
# @title: gio save reads stdin and writes the exact payload to the destination file
# @description: Pipes a deterministic ASCII payload into gio save and asserts the destination file in tmpdir contains exactly those bytes when read back with cat, exercising the gio save stdin-to-file projection distinct from copy and rename-based content checks.
# @timeout: 60
# @tags: usage, gio, save, stdin, r19
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

payload='r19-gio-save-stdin-marker'
printf '%s' "$payload" | gio save "$tmpdir/saved.txt"
got=$(cat "$tmpdir/saved.txt")
[[ "$got" == "$payload" ]] || {
    printf 'mismatch expected=%q got=%q\n' "$payload" "$got" >&2
    exit 1
}
