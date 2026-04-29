#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-two-topdirs-list
# @title: libarchive-tools xz two topdirs list
# @description: Creates an xz-compressed tar with two top-level directories and verifies both paths appear in the archive listing.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libarchive-tools-xz-two-topdirs-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/top1" "$tmpdir/in/top2"
printf 'alpha\n' >"$tmpdir/in/top1/alpha.txt"
printf 'beta\n' >"$tmpdir/in/top2/beta.txt"
bsdtar -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" top1 top2
bsdtar -tf "$tmpdir/a.tar.xz" | tee "$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'top1/alpha.txt'
validator_assert_contains "$tmpdir/list" 'top2/beta.txt'
