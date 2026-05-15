#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-bsdtar-tjf-lists-two-members
# @title: bsdtar -tJf on a tar.xz with two files lists exactly two member names
# @description: Creates a tar.xz containing two distinct files via bsdtar -cJf, runs bsdtar -tJf to list contents, and asserts the listing has exactly two lines and contains both expected basenames, pinning the multi-member listing path through libarchive's xz filter.
# @timeout: 60
# @tags: usage, bsdtar, xz, list, members, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
printf 'first\n'  >"$tmpdir/src/a.txt"
printf 'second\n' >"$tmpdir/src/b.txt"

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" a.txt b.txt)
bsdtar -tJf "$tmpdir/out.tar.xz" >"$tmpdir/list.txt"

count=$(wc -l <"$tmpdir/list.txt")
[[ "$count" -eq 2 ]] || { printf 'expected 2 members, got %s\n' "$count" >&2; cat "$tmpdir/list.txt" >&2; exit 1; }
grep -Fxq 'a.txt' "$tmpdir/list.txt"
grep -Fxq 'b.txt' "$tmpdir/list.txt"
