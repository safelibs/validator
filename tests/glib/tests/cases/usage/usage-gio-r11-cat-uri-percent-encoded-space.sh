#!/usr/bin/env bash
# @testcase: usage-gio-r11-cat-uri-percent-encoded-space
# @title: gio cat resolves a percent-encoded space in a file:// URI
# @description: Writes a payload to a path containing a literal space, accesses it via a file:// URI with the space percent-encoded as %20, and verifies that gio cat reads the same byte-for-byte payload back.
# @timeout: 60
# @tags: usage, gio, cat, uri
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir "$tmpdir/has space"
payload='gio-r11 percent-encoded space payload'
printf '%s\n' "$payload" >"$tmpdir/has space/data.txt"

uri="file://$tmpdir/has%20space/data.txt"
gio cat "$uri" >"$tmpdir/out"
diff -- "$tmpdir/out" "$tmpdir/has space/data.txt"
