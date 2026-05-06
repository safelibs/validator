#!/usr/bin/env bash
# @testcase: usage-gio-r11-info-edit-name-equals-basename
# @title: gio info standard::edit-name returns the file basename for plain files
# @description: Creates a regular file with a deterministic basename and verifies that "gio info -a standard::edit-name" reports the basename verbatim under the attributes block.
# @timeout: 60
# @tags: usage, gio, info, attribute
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

basename="r11-edit-name-fixture.txt"
echo "fixture" >"$tmpdir/$basename"
gio info -a standard::edit-name "$tmpdir/$basename" >"$tmpdir/out"
value=$(awk -F': ' '/^  standard::edit-name:/ {print $2; exit}' "$tmpdir/out")
[[ "$value" == "$basename" ]] || { printf 'expected=%s got=%s\n' "$basename" "$value" >&2; sed -n '1,40p' "$tmpdir/out" >&2; exit 1; }
