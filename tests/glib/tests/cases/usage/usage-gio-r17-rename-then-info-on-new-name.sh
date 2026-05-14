#!/usr/bin/env bash
# @testcase: usage-gio-r17-rename-then-info-on-new-name
# @title: gio rename renames a file and gio info reports the new basename verbatim
# @description: Creates a tmpdir file r17-old.bin, renames it to r17-new.bin via gio rename, and asserts gio info --attributes=standard::display-name on the new path reports the new basename verbatim, exercising the rename-then-info sequence on local URIs.
# @timeout: 60
# @tags: usage, gio, rename
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/r17-old.bin"
gio rename "$tmpdir/r17-old.bin" 'r17-new.bin'
[[ -e "$tmpdir/r17-new.bin" ]] || {
    printf 'expected renamed file to exist: %s/r17-new.bin\n' "$tmpdir" >&2
    exit 1
}
[[ ! -e "$tmpdir/r17-old.bin" ]] || {
    printf 'expected old name gone: %s/r17-old.bin\n' "$tmpdir" >&2
    exit 1
}

gio info --attributes='standard::display-name' "$tmpdir/r17-new.bin" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'r17-new.bin'
