#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r9-bsdtar-numeric-owner
# @title: bsdtar zstd numeric-owner listing
# @description: Lists a zstd-compressed archive with --numeric-owner and verifies the owner column contains an integer (uid) rather than a name.
# @timeout: 180
# @tags: usage, archive, zstd
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'numeric owner test\n' >"$tmpdir/in/file.txt"

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" file.txt
bsdtar -tvf "$tmpdir/a.tar.zst" --numeric-owner >"$tmpdir/list"

# bsdtar prints "<perm> <links> <uid> <gid> <size> <date> <name>". Verify both
# the uid (column 3) and gid (column 4) are decimal integers under --numeric-owner.
awk 'NR==1 {print $3, $4}' "$tmpdir/list" >"$tmpdir/owner"
grep -Eq '^[0-9]+ [0-9]+$' "$tmpdir/owner" || {
  echo "owner field not numeric:" >&2
  cat "$tmpdir/list" >&2
  exit 1
}
