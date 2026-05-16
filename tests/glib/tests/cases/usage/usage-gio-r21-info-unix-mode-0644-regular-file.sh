#!/usr/bin/env bash
# @testcase: usage-gio-r21-info-unix-mode-0644-regular-file
# @title: gio info reports unix::mode 33188 for a chmod 0644 regular file
# @description: Creates a tmpdir file, chmods it to 0644, and asserts gio info -a unix::mode emits the line "unix::mode: 33188" matching the regular-file type bits (S_IFREG=0o100000=32768) plus 0644 permission bits (420), exercising the unix::mode attribute on the common 0644 mode distinct from the existing 0600 (r19) and 0755 (r20) cases.
# @timeout: 60
# @tags: usage, gio, info, unix-mode, r21
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

target="$tmpdir/file.txt"
printf 'r21 mode 0644\n' >"$target"
chmod 0644 "$target"
gio info -a unix::mode "$target" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'unix::mode: 33188'
