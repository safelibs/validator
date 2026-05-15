#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r20-xz-version-reports-liblzma
# @title: xz --version output mentions liblzma
# @description: Runs xz --version and asserts the output contains the substring "liblzma", pinning that the xz CLI advertises its underlying decompression library in the version banner on Ubuntu 24.04.
# @timeout: 30
# @tags: usage, xz, version, banner, r20
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xz --version >"$tmpdir/ver.txt" 2>&1
validator_require_file "$tmpdir/ver.txt"
grep -Fq 'liblzma' "$tmpdir/ver.txt"
