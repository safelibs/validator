#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r14-unxz-explicit-keep
# @title: unxz --keep preserves the .xz input and writes the decoded sibling
# @description: Compresses a payload to .xz, then runs "unxz --keep" against it and asserts both the .xz file and the decoded sibling exist, and the decoded contents match the original sha256 — confirming unxz honours --keep distinct from xz -dk and the existing unxz-roundtrip case.
# @timeout: 60
# @tags: usage, unxz, keep
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'unxz keep payload alpha beta\nrow two\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.xz" ]]
[[ ! -e "$tmpdir/in.txt" ]]

unxz --keep "$tmpdir/in.txt.xz"

[[ -f "$tmpdir/in.txt.xz" ]]
[[ -f "$tmpdir/in.txt" ]]

out_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
