#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-bsdtar-capj-create-roundtrip
# @title: bsdtar -cJf xz tarball roundtrip with three entries
# @description: Builds a tar.xz archive with "bsdtar -cJf" against a directory of three files, asserts the .xz magic, lists members via "bsdtar -tf" matching the input set, and extracts to a fresh tree confirming each file's sha256 matches its source.
# @timeout: 120
# @tags: usage, bsdtar, xz, J
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'capJ alpha\n' >"$tmpdir/in/alpha.txt"
printf 'capJ beta longer payload\n' >"$tmpdir/in/beta.txt"
printf 'capJ gamma final\n' >"$tmpdir/in/gamma.txt"

a_sha=$(sha256sum "$tmpdir/in/alpha.txt" | awk '{print $1}')
b_sha=$(sha256sum "$tmpdir/in/beta.txt" | awk '{print $1}')
g_sha=$(sha256sum "$tmpdir/in/gamma.txt" | awk '{print $1}')

bsdtar -cJf "$tmpdir/out.tar.xz" -C "$tmpdir/in" alpha.txt beta.txt gamma.txt

magic_hex=$(head -c 6 "$tmpdir/out.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/out.tar.xz" | sort >"$tmpdir/list.txt"
printf 'alpha.txt\nbeta.txt\ngamma.txt\n' | sort >"$tmpdir/expected.txt"
diff -u "$tmpdir/expected.txt" "$tmpdir/list.txt"

bsdtar -xf "$tmpdir/out.tar.xz" -C "$tmpdir/out"

test "$a_sha" = "$(sha256sum "$tmpdir/out/alpha.txt" | awk '{print $1}')"
test "$b_sha" = "$(sha256sum "$tmpdir/out/beta.txt" | awk '{print $1}')"
test "$g_sha" = "$(sha256sum "$tmpdir/out/gamma.txt" | awk '{print $1}')"
