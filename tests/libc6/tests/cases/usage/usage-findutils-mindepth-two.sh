#!/usr/bin/env bash
# @testcase: usage-findutils-mindepth-two
# @title: findutils -mindepth 2 skips top-level entries
# @description: Builds a nested fixture tree and verifies find -mindepth 2 lists exactly the entries below the top-level directories.
# @timeout: 180
# @tags: usage, findutils
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-mindepth-two"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/root/a/sub" "$tmpdir/root/b"
: >"$tmpdir/root/top.txt"
: >"$tmpdir/root/a/inside-a.txt"
: >"$tmpdir/root/a/sub/deep.txt"
: >"$tmpdir/root/b/inside-b.txt"

# -mindepth 2 means "at least two path components below the starting point",
# i.e. exclude the starting point itself and its direct children.
find "$tmpdir/root" -mindepth 2 | LC_ALL=C sort >"$tmpdir/out"

test "$(wc -l <"$tmpdir/out")" -eq 4
grep -Fxq "$tmpdir/root/a/inside-a.txt" "$tmpdir/out"
grep -Fxq "$tmpdir/root/a/sub" "$tmpdir/out"
grep -Fxq "$tmpdir/root/a/sub/deep.txt" "$tmpdir/out"
grep -Fxq "$tmpdir/root/b/inside-b.txt" "$tmpdir/out"

# Top-level entries must be excluded.
! grep -Fxq "$tmpdir/root" "$tmpdir/out"
! grep -Fxq "$tmpdir/root/a" "$tmpdir/out"
! grep -Fxq "$tmpdir/root/b" "$tmpdir/out"
! grep -Fxq "$tmpdir/root/top.txt" "$tmpdir/out"
