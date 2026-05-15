#!/usr/bin/env bash
# @testcase: usage-gio-r19-info-standard-content-type-text-plain-utf8
# @title: gio info standard::content-type for a .txt fixture starts with text/
# @description: Creates a tmpdir text file with a UTF-8 ASCII payload, runs gio info -a standard::content-type, and asserts the rendered attribute line starts with "standard::content-type: text/" reflecting the textual mime category, exercising the content-type sniffer distinct from prior mime-handler tests.
# @timeout: 60
# @tags: usage, gio, info, content-type, r19
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r19 content type sniff\n' >"$tmpdir/doc.txt"
gio info -a standard::content-type "$tmpdir/doc.txt" >"$tmpdir/info.txt"
grep -Eq '^[[:space:]]+standard::content-type: text/' "$tmpdir/info.txt" || {
    printf 'expected text/ content-type:\n' >&2
    sed -n '1,40p' "$tmpdir/info.txt" >&2
    exit 1
}
