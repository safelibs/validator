#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r17-bsdtar-tvjf-shows-user-group-columns
# @title: bsdtar -tvJf shows user/group columns for entries written with --uname/--gname
# @description: Creates a tar.xz with bsdtar --uname=alpha --gname=beta and asserts that bsdtar -tvJf verbose listing includes both alpha and beta strings, exercising the libarchive name override round-trip on xz-compressed archives.
# @timeout: 60
# @tags: usage, bsdtar, xz, names
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/src"
printf 'payload\n' >"$tmpdir/src/file.txt"

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" --uname=alpha --gname=beta file.txt)
validator_require_file "$tmpdir/out.tar.xz"

bsdtar -tvJf "$tmpdir/out.tar.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'alpha'
validator_assert_contains "$tmpdir/list.txt" 'beta'
