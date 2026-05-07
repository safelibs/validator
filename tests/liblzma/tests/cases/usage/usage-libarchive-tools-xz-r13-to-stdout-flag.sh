#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-to-stdout-flag
# @title: xz --to-stdout long form writes compressed output to stdout
# @description: Runs "xz --to-stdout" with a positional input and asserts the input file remains untouched, the captured stdout starts with the .xz magic bytes, and decoding it back via xz -d -c yields the source content via sha256.
# @timeout: 60
# @tags: usage, xz, stdout
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'to-stdout payload alpha beta\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz --to-stdout "$tmpdir/in.txt" >"$tmpdir/out.xz"

# Source must be untouched.
[[ -f "$tmpdir/in.txt" ]]
post_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
test "$src_sha" = "$post_sha"
[[ ! -e "$tmpdir/in.txt.xz" ]]

magic_hex=$(head -c 6 "$tmpdir/out.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz -d -c "$tmpdir/out.xz" >"$tmpdir/decoded.txt"
test "$src_sha" = "$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')"
