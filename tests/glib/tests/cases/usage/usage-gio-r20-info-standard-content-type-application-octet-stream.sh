#!/usr/bin/env bash
# @testcase: usage-gio-r20-info-standard-content-type-application-octet-stream
# @title: gio info standard::content-type reports application/octet-stream on a .bin file
# @description: Creates a tmpdir/data.bin file with binary header bytes 00 01 02 03 and runs gio info -a standard::content-type on it, asserting the output contains the line "standard::content-type: application/octet-stream", exercising the MIME-type sniffer mapping for binary data distinct from prior text/plain-on-txt cases.
# @timeout: 60
# @tags: usage, gio, info, content-type, r20
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '\x00\x01\x02\x03\xff\xfe\xfd\xfc' >"$tmpdir/data.bin"
gio info -a standard::content-type "$tmpdir/data.bin" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'standard::content-type: application/octet-stream'
