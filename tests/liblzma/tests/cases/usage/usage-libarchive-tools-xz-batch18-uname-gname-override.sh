#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch18-uname-gname-override
# @title: bsdtar --uname/--gname override in xz tar
# @description: Creates a tar.xz with bsdtar --uname=valuser --gname=valgrp and confirms verbose listing of the xz-compressed archive shows the override owner labels for every entry.
# @timeout: 180
# @tags: usage, archive, xz, owner
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/sub" "$tmpdir/out"
printf 'owner override alpha\n' >"$tmpdir/src/alpha.txt"
printf 'owner override gamma\n' >"$tmpdir/src/sub/gamma.txt"

bsdtar --uname=valuser --gname=valgrp -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/src" alpha.txt sub

magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tvf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'valuser'
validator_assert_contains "$tmpdir/list.txt" 'valgrp'
validator_assert_contains "$tmpdir/list.txt" 'alpha.txt'
validator_assert_contains "$tmpdir/list.txt" 'sub/gamma.txt'

# Every non-empty data line must contain the override labels.
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  case "$line" in
    *valuser*valgrp*|*valuser/valgrp*) : ;;
    *)
      printf 'line missing override owner labels: %s\n' "$line" >&2
      exit 1
      ;;
  esac
done <"$tmpdir/list.txt"
