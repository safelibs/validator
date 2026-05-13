#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r16-bsdtar-tjf-emits-tar-listing
# @title: bsdtar -tjf on a tar.xz round-trip lists exactly the input filenames
# @description: Builds a 3-file tree, packs with bsdtar -cJf into a tar.xz, then lists with bsdtar -tjf and asserts the captured listing contains all 3 filenames and exactly 3 non-empty lines.
# @timeout: 120
# @tags: usage, bsdtar, xz, list
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'alpha\n' >"$tmpdir/src/alpha.txt"
printf 'beta\n' >"$tmpdir/src/beta.txt"
printf 'gamma\n' >"$tmpdir/src/gamma.txt"

(cd "$tmpdir/src" && bsdtar -cJf "$tmpdir/out.tar.xz" alpha.txt beta.txt gamma.txt)
bsdtar -tjf "$tmpdir/out.tar.xz" >"$tmpdir/list.txt"

validator_assert_contains "$tmpdir/list.txt" 'alpha.txt'
validator_assert_contains "$tmpdir/list.txt" 'beta.txt'
validator_assert_contains "$tmpdir/list.txt" 'gamma.txt'
count=$(grep -cve '^$' "$tmpdir/list.txt")
test "$count" -eq 3
