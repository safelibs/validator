#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r9-uname-tag
# @title: bsdtar xz uname override via --uname
# @description: Creates an xz tarball with --uname=customuser --gname=customgrp and verifies the verbose listing surfaces those names.
# @timeout: 180
# @tags: usage, archive, compression
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"
printf 'uname tag\n' >"$tmpdir/in/file.txt"
( cd "$tmpdir/in" && bsdtar --uname=customuser --gname=customgrp -cJf "$tmpdir/a.tar.xz" file.txt )

bsdtar -tvf "$tmpdir/a.tar.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'customuser'
validator_assert_contains "$tmpdir/list.txt" 'customgrp'
