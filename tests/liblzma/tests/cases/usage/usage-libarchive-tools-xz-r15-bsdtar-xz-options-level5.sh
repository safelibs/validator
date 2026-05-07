#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-bsdtar-xz-options-level5
# @title: bsdtar --xz --options compression-level=5 round trips a tar.xz archive
# @description: Builds a tar.xz with "bsdtar --xz --options compression-level=5" (the default-tier preset distinct from existing level0/1/2/3/4/9 cases), asserts the .xz magic, lists members via "bsdtar -tJf" matching the input filenames, and extracts to a fresh tree confirming each file's sha256 matches the source.
# @timeout: 120
# @tags: usage, bsdtar, xz, options, level5
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'r15 level5 alpha\n' >"$tmpdir/in/alpha.txt"
printf 'r15 level5 beta payload\n' >"$tmpdir/in/beta.txt"

a_sha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
b_sha=$(sha256sum "$tmpdir/in/beta.txt" | awk '{print $1}')

bsdtar --xz --options compression-level=5 -cf "$tmpdir/out.tar.xz" \
    -C "$tmpdir/in" alpha.txt beta.txt

magic_hex=$(head -c 6 "$tmpdir/out.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tJf "$tmpdir/out.tar.xz" | sort >"$tmpdir/list.txt"
printf 'alpha.txt\nbeta.txt\n' | sort >"$tmpdir/expected.txt"
diff -u "$tmpdir/expected.txt" "$tmpdir/list.txt"

bsdtar -xf "$tmpdir/out.tar.xz" -C "$tmpdir/out"

test "$a_sha" = "$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')"
test "$b_sha" = "$(sha256sum "$tmpdir/out/beta.txt" | awk '{print $1}')"
