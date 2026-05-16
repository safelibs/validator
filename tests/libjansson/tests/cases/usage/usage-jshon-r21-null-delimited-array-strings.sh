#!/usr/bin/env bash
# @testcase: usage-jshon-r21-null-delimited-array-strings
# @title: jshon -0 -a -u emits NUL-separated unstring tokens for an array of strings
# @description: Pipes a JSON array of three short strings ["alpha","beta","gamma"] through jshon -0 -a -u and asserts the resulting byte stream is exactly the three strings each followed by a NUL byte (no trailing newline) - locking in libjansson-backed jshon's NUL-delimited emission mode when un-stringing across an array.
# @timeout: 30
# @tags: usage, json, cli, null-delim, array, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '["alpha","beta","gamma"]' | jshon -0 -a -u >"$tmpdir/out.bin"

# Build expected byte stream.
printf 'alpha\0beta\0gamma\0' >"$tmpdir/exp.bin"

cmp -s "$tmpdir/out.bin" "$tmpdir/exp.bin" || {
    echo 'unexpected NUL-delimited output bytes' >&2
    od -c "$tmpdir/out.bin" >&2
    echo --expected-- >&2
    od -c "$tmpdir/exp.bin" >&2
    exit 1
}
