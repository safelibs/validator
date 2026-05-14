#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-bsdtar-exclude-pattern
# @title: bsdtar -cJf --exclude omits matching files from the tar.xz
# @description: Creates a tar.xz with bsdtar -cJf --exclude='*.skip' over a directory containing keep and skip files, then asserts the listing includes keep.txt but not skip.skip — pinning the libarchive exclude pattern on xz archives.
# @timeout: 60
# @tags: usage, bsdtar, xz, exclude, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
printf 'keep\n' >"$tmpdir/src/keep.txt"
printf 'drop\n' >"$tmpdir/src/skip.skip"

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" --exclude='*.skip' keep.txt skip.skip)

bsdtar -tJf "$tmpdir/out.tar.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'keep.txt'

if grep -Fq 'skip.skip' "$tmpdir/list.txt"; then
  printf 'skip.skip should have been excluded\n' >&2
  exit 1
fi
