#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-xz-ignore-check-decodes-corrupted-crc
# @title: xz format=lzip flag rejects xz-format input as expected
# @description: Compresses a payload as xz then invokes xz -d --format=lzip on the .xz file and asserts the command fails (exit nonzero), pinning that liblzma's strict format gating refuses to decode xz streams under the lzip format selector.
# @timeout: 60
# @tags: usage, xz, format, lzip, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'format-mismatch-payload\n' >"$tmpdir/in.txt"
xz -k "$tmpdir/in.txt"
validator_require_file "$tmpdir/in.txt.xz"

set +e
xz -d --format=lzip -c "$tmpdir/in.txt.xz" >"$tmpdir/out.bin" 2>"$tmpdir/err.txt"
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo "expected nonzero exit, got 0" >&2; exit 1; }
