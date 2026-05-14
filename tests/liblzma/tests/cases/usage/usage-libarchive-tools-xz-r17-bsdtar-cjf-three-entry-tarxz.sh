#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-bsdtar-cjf-three-entry-tarxz
# @title: bsdtar -cJf creates a tar.xz containing three files
# @description: Creates a tar.xz via bsdtar -cJf from a directory with three files and asserts bsdtar -tJf lists all three filenames, exercising the libarchive write-and-read xz path on a multi-entry archive.
# @timeout: 60
# @tags: usage, bsdtar, xz, tar
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
printf 'alpha\n' >"$tmpdir/src/a.txt"
printf 'beta\n'  >"$tmpdir/src/b.txt"
printf 'gamma\n' >"$tmpdir/src/c.txt"

(cd "$tmpdir" && bsdtar -cJf out.tar.xz -C src a.txt b.txt c.txt)
validator_require_file "$tmpdir/out.tar.xz"

bsdtar -tJf "$tmpdir/out.tar.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'a.txt'
validator_assert_contains "$tmpdir/list.txt" 'b.txt'
validator_assert_contains "$tmpdir/list.txt" 'c.txt'
