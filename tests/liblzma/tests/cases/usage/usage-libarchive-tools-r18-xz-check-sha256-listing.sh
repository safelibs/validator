#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-xz-check-sha256-listing
# @title: xz --check=sha256 stream lists SHA-256 as the integrity check
# @description: Compresses a payload with xz --check=sha256 and asserts xz --list -vv reports SHA-256 in its detailed listing of the produced stream, pinning the non-default integrity-check selection through the liblzma encoder.
# @timeout: 60
# @tags: usage, xz, check, sha256, list, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r18 sha256 check payload\n' >"$tmpdir/in.txt"
xz --check=sha256 -c "$tmpdir/in.txt" >"$tmpdir/in.xz"

xz --list -vv "$tmpdir/in.xz" >"$tmpdir/listing.txt"
validator_assert_contains "$tmpdir/listing.txt" 'SHA-256'
