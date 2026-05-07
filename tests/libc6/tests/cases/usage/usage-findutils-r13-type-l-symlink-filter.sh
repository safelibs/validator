#!/usr/bin/env bash
# @testcase: usage-findutils-r13-type-l-symlink-filter
# @title: findutils find -type l selects only symbolic links via libc lstat
# @description: Builds a directory containing a regular file, a directory, and a symlink, then runs find -type l and asserts only the symlink is reported.
# @timeout: 60
# @tags: usage, findutils, symlink, lstat
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/d/sub"
: >"$tmpdir/d/regular.txt"
ln -s regular.txt "$tmpdir/d/link.txt"

LC_ALL=C find "$tmpdir/d" -mindepth 1 -maxdepth 1 -type l -printf '%f\n' \
  | LC_ALL=C sort >"$tmpdir/got.txt"

[[ "$(cat "$tmpdir/got.txt")" == "link.txt" ]]
