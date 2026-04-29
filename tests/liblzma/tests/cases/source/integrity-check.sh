#!/usr/bin/env bash
# @testcase: integrity-check
# @title: xz integrity check
# @description: Creates a CRC64 checked stream and verifies it with xz test mode.
# @timeout: 120
# @tags: cli, integrity

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'integrity\n' >"$tmpdir/plain"; xz --check=crc64 -c "$tmpdir/plain" >"$tmpdir/a.xz"; xz --test "$tmpdir/a.xz"; xz --list --verbose "$tmpdir/a.xz" | tee "$tmpdir/list"; grep -i CRC64 "$tmpdir/list"
