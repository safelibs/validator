#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-bsdtar-cjf-then-list-xz-tarball
# @title: bsdtar -cJf produces a tar.xz whose listing matches the input set
# @description: Creates a tar.xz of three text files using bsdtar -cJf and runs bsdtar -tJf to list the archive, asserting all three filenames appear in the listing, pinning libarchive's xz writer + reader symmetry.
# @timeout: 60
# @tags: usage, bsdtar, xz, listing, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
printf 'one\n'   >"$tmpdir/src/one.txt"
printf 'two\n'   >"$tmpdir/src/two.txt"
printf 'three\n' >"$tmpdir/src/three.txt"

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" one.txt two.txt three.txt)
bsdtar -tJf "$tmpdir/out.tar.xz" >"$tmpdir/list.txt"

validator_assert_contains "$tmpdir/list.txt" 'one.txt'
validator_assert_contains "$tmpdir/list.txt" 'two.txt'
validator_assert_contains "$tmpdir/list.txt" 'three.txt'
