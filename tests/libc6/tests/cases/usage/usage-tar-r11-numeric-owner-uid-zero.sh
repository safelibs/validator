#!/usr/bin/env bash
# @testcase: usage-tar-r11-numeric-owner-uid-zero
# @title: tar --numeric-owner --owner=0 records uid 0 verbatim in archive metadata
# @description: Creates a tar with --numeric-owner --owner=0 --group=0 and verifies the archive listing reports owner 0/0 exercising tar libc-getpwuid bypass and explicit numeric ownership.
# @timeout: 60
# @tags: usage, tar, numeric-owner
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'tar numeric owner test\n' >"$tmpdir/src/file.txt"

LC_ALL=C tar --numeric-owner --owner=0 --group=0 -cf "$tmpdir/out.tar" -C "$tmpdir" src

LC_ALL=C tar --numeric-owner -tvf "$tmpdir/out.tar" >"$tmpdir/listing.txt"
LC_ALL=C grep -F ' 0/0 ' "$tmpdir/listing.txt" >/dev/null
