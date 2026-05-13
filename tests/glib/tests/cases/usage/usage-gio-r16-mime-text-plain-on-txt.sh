#!/usr/bin/env bash
# @testcase: usage-gio-r16-mime-text-plain-on-txt
# @title: gio info --attributes=standard::content-type returns text/plain for a .txt file
# @description: Writes an ASCII payload to a .txt file and asserts gio info --attributes=standard::content-type reports text/plain for the path, exercising the GIO content-type query against shared-mime-info.
# @timeout: 60
# @tags: usage, gio, info, mime
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'hello r16 mime\n' >"$tmpdir/note.txt"
gio info --attributes='standard::content-type' "$tmpdir/note.txt" >"$tmpdir/out.txt"

validator_assert_contains "$tmpdir/out.txt" 'standard::content-type: text/plain'
