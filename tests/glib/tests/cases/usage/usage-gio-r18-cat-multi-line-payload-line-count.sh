#!/usr/bin/env bash
# @testcase: usage-gio-r18-cat-multi-line-payload-line-count
# @title: gio cat reads a three-line tmpdir fixture and emits the same line count
# @description: Writes a three-line ASCII fixture into a tmpdir and asserts gio cat emits exactly three newline-terminated lines on stdout, exercising the gio CLI local read path on a small multi-line payload distinct from single-line marker tests.
# @timeout: 60
# @tags: usage, gio, cat, multi-line, r18
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r18-line-one\nr18-line-two\nr18-line-three\n' >"$tmpdir/payload.txt"
gio cat "$tmpdir/payload.txt" >"$tmpdir/out"
lines=$(wc -l <"$tmpdir/out")
[[ "$lines" -eq 3 ]] || {
    printf 'expected 3 lines, got %s\n' "$lines" >&2
    sed -n '1,10p' "$tmpdir/out" >&2
    exit 1
}
