#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch14-files-from-pipe
# @title: bsdtar xz --files-from stdin pipe
# @description: Pipes a newline-delimited file list into bsdtar via --files-from=- and verifies the resulting tar.xz contains exactly the listed members.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'pipe one\n' >"$tmpdir/in/one.txt"
printf 'pipe two\n' >"$tmpdir/in/two.txt"
printf 'pipe skip\n' >"$tmpdir/in/skip.txt"

# Send the file list through stdin via --files-from=-.
printf 'one.txt\ntwo.txt\n' \
  | bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" --files-from=-

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" | sort >"$tmpdir/list.txt"
printf 'one.txt\ntwo.txt\n' | sort >"$tmpdir/expected.txt"
diff -u "$tmpdir/expected.txt" "$tmpdir/list.txt"

bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp "$tmpdir/in/one.txt" "$tmpdir/out/one.txt"
cmp "$tmpdir/in/two.txt" "$tmpdir/out/two.txt"
test ! -e "$tmpdir/out/skip.txt"
