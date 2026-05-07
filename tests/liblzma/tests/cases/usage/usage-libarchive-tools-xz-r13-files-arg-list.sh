#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-files-arg-list
# @title: xz --files= reads filenames from a newline-delimited list file
# @description: Builds a list file containing two newline-separated source paths and runs "xz --files=list.txt --keep" so xz reads the targets from the file rather than argv. Asserts both .xz outputs are produced, both decode roundtrip, and skips an unlisted third file in the same directory.
# @timeout: 120
# @tags: usage, xz, files
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'alpha payload one\n' >"$tmpdir/in/one.txt"
printf 'beta payload two\n' >"$tmpdir/in/two.txt"
printf 'unlisted skip\n' >"$tmpdir/in/three.txt"

a_sha=$(sha256sum "$tmpdir/in/one.txt" | awk '{print $1}')
b_sha=$(sha256sum "$tmpdir/in/two.txt" | awk '{print $1}')

printf '%s\n%s\n' "$tmpdir/in/one.txt" "$tmpdir/in/two.txt" >"$tmpdir/list.txt"

xz --keep --files="$tmpdir/list.txt"

[[ -f "$tmpdir/in/one.txt.xz" ]]
[[ -f "$tmpdir/in/two.txt.xz" ]]
[[ ! -e "$tmpdir/in/three.txt.xz" ]]

xz -dc "$tmpdir/in/one.txt.xz" >"$tmpdir/d1.txt"
xz -dc "$tmpdir/in/two.txt.xz" >"$tmpdir/d2.txt"

test "$a_sha" = "$(sha256sum "$tmpdir/d1.txt" | awk '{print $1}')"
test "$b_sha" = "$(sha256sum "$tmpdir/d2.txt" | awk '{print $1}')"
