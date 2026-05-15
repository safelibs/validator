#!/usr/bin/env bash
# @testcase: usage-gio-r20-info-unix-mode-0755-attribute
# @title: gio info reports unix::mode 33261 for a chmod 0755 regular file
# @description: Creates a tmpdir file, chmods it to 0755, and asserts gio info -a unix::mode emits the line "unix::mode: 33261" matching the regular-file type bits (S_IFREG=0o100000=32768) plus 0755 permission bits (493), exercising the unix::mode attribute distinct from the existing 0600 case in r19.
# @timeout: 60
# @tags: usage, gio, info, unix-mode, r20
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r20-unix-mode-755\n' >"$tmpdir/exec.sh"
chmod 0755 "$tmpdir/exec.sh"
gio info -a unix::mode "$tmpdir/exec.sh" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'unix::mode: 33261'
