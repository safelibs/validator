#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-exclude-pattern
# @title: libarchive-tools xz exclude pattern
# @description: Creates an xz-compressed tar archive with an exclude pattern and verifies omitted files.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-exclude-pattern"
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
bsdtar --exclude '*beta*' -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .
bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'alpha.txt'
if grep -Fq 'beta.txt' "$tmpdir/list"; then exit 1; fi
