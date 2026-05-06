#!/usr/bin/env bash
# @testcase: usage-gio-r11-info-id-file-attribute-non-empty
# @title: gio info exposes id::file attribute as a non-empty string
# @description: Creates a regular file and verifies "gio info -a id::file" prints the id::file attribute as a non-empty string token (kernel-formatted device:inode pair) under the attributes block.
# @timeout: 60
# @tags: usage, gio, info, attribute
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "payload" >"$tmpdir/x"
gio info -a id::file "$tmpdir/x" >"$tmpdir/out"
value=$(awk -F': ' '/^  id::file:/ {print $2; exit}' "$tmpdir/out")
[[ -n "$value" ]] || { sed -n '1,40p' "$tmpdir/out" >&2; exit 1; }
