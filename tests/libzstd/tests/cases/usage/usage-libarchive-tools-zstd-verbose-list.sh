#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-verbose-list
# @title: libarchive-tools zstd verbose list
# @description: Lists a zstd-compressed tar archive verbosely and verifies mode metadata.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-zstd-verbose-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

make_tree() {
  mkdir -p "$tmpdir/in/dir/sub" "$tmpdir/out"
  printf 'alpha payload\n' >"$tmpdir/in/alpha.txt"
  printf 'beta payload\n' >"$tmpdir/in/dir/beta.txt"
  printf 'gamma payload\n' >"$tmpdir/in/dir/sub/gamma.txt"
  printf 'space payload\n' >"$tmpdir/in/space name.txt"
}

make_tree
chmod 755 "$tmpdir/in/alpha.txt"
bsdtar --zstd -cf "$tmpdir/a.tar.zstd" -C "$tmpdir/in" alpha.txt
bsdtar -tvf "$tmpdir/a.tar.zstd" | tee "$tmpdir/list"
grep -Eq '^-rwx' "$tmpdir/list"
