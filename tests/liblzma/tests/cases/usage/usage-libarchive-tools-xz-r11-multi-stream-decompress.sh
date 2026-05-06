#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r11-multi-stream-decompress
# @title: xz -d concatenates multiple .xz streams in one decode
# @description: Concatenates two independently compressed .xz streams and verifies "xz -dc" emits both payloads in order while "xz --robot --list" reports a totals row with two streams and two blocks.
# @timeout: 60
# @tags: usage, xz, multi-stream
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first-stream-payload-alpha\n' >"$tmpdir/a.txt"
printf 'second-stream-payload-beta\n' >"$tmpdir/b.txt"

xz -c "$tmpdir/a.txt" >"$tmpdir/a.xz"
xz -c "$tmpdir/b.txt" >"$tmpdir/b.xz"
cat "$tmpdir/a.xz" "$tmpdir/b.xz" >"$tmpdir/both.xz"

xz -dc "$tmpdir/both.xz" >"$tmpdir/decoded.txt"
expected="first-stream-payload-alpha
second-stream-payload-beta"
actual=$(cat "$tmpdir/decoded.txt")
test "$actual" = "$expected"

xz --robot --list "$tmpdir/both.xz" >"$tmpdir/list.txt"
totals_streams=$(awk '$1=="totals"{print $2}' "$tmpdir/list.txt")
totals_blocks=$(awk '$1=="totals"{print $3}' "$tmpdir/list.txt")
test "$totals_streams" = "2"
test "$totals_blocks" = "2"
