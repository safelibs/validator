#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-rootdir-hidden-file
# @title: libarchive-tools xz root hidden file
# @description: Archives and extracts a hidden file under a root directory in an xz-compressed tar and verifies the restored payload.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-rootdir-hidden-file"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/root" "$tmpdir/out"
printf 'hidden payload\n' >"$tmpdir/in/root/.hidden"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" root
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
validator_assert_contains "$tmpdir/out/root/.hidden" 'hidden payload'
