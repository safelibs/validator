#!/usr/bin/env bash
# @testcase: usage-gio-r19-info-unix-mode-0600-attribute
# @title: gio info reports unix::mode 33152 for a chmod 0600 regular file
# @description: Creates a tmpdir file, chmods it to 0600, and asserts gio info -a unix::mode reports the attribute line "unix::mode: 33152" matching the regular-file type bits plus 0600 permission bits, exercising the unix::mode attribute query distinct from prior list-format tests.
# @timeout: 60
# @tags: usage, gio, info, unix-mode, r19
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r19-unix-mode\n' >"$tmpdir/secret.txt"
chmod 0600 "$tmpdir/secret.txt"
gio info -a unix::mode "$tmpdir/secret.txt" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'unix::mode: 33152'
