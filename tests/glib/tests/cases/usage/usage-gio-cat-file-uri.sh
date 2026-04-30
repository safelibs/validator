#!/usr/bin/env bash
# @testcase: usage-gio-cat-file-uri
# @title: gio cat file URI
# @description: Reads a local file through a file:// URI with gio cat and verifies the emitted bytes.
# @timeout: 180
# @tags: usage, gio, uri
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-cat-file-uri"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

payload='gio cat uri payload'
printf '%s\n' "$payload" >"$tmpdir/input.txt"

uri=$(python3 -c 'import sys, urllib.parse; print("file://" + urllib.parse.quote(sys.argv[1]))' "$tmpdir/input.txt")
gio cat "$uri" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" "$payload"
