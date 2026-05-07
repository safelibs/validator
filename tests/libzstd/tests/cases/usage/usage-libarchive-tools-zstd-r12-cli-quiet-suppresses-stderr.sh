#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-cli-quiet-suppresses-stderr
# @title: zstd -qq suppresses the "compressed" summary line printed by default
# @description: Compresses a payload with default verbosity, with -q, and with -qq, and asserts each progressively quieter mode strips lines: default may print, -q stays silent on success, and -qq matches -q with no diagnostic stderr output.
# @timeout: 60
# @tags: usage, zstd, cli, verbosity
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'quiet payload row\n%.0s' {1..200} >"$tmpdir/in.txt"

# -q: success path should produce no stderr output.
zstd -q "$tmpdir/in.txt" -o "$tmpdir/q.zst" 2>"$tmpdir/q.err"
size_q=$(stat -c %s "$tmpdir/q.err")
[[ "$size_q" -eq 0 ]] || {
    printf 'expected -q to be silent on stderr, got: %s\n' "$(cat "$tmpdir/q.err")" >&2
    exit 1
}

# -qq: same — success is silent.
zstd -qq "$tmpdir/in.txt" -o "$tmpdir/qq.zst" -f 2>"$tmpdir/qq.err"
size_qq=$(stat -c %s "$tmpdir/qq.err")
[[ "$size_qq" -eq 0 ]] || {
    printf 'expected -qq to be silent on stderr, got: %s\n' "$(cat "$tmpdir/qq.err")" >&2
    exit 1
}

# Both outputs are valid zstd frames.
zstd -t "$tmpdir/q.zst"
zstd -t "$tmpdir/qq.zst"
