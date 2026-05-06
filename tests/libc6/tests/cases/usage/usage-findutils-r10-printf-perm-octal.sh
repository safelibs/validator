#!/usr/bin/env bash
# @testcase: usage-findutils-r10-printf-perm-octal
# @title: find -printf %m emits the octal permission bits from libc stat
# @description: Creates a file with mode 0644, runs find with -printf %m, and verifies the emitted octal mode equals 644 — exercising the libc stat path that supplies st_mode.
# @timeout: 60
# @tags: usage, findutils
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

f="$tmpdir/file.bin"
: >"$f"
chmod 0644 "$f"
got=$(LC_ALL=C find "$f" -maxdepth 0 -printf '%m\n')
[[ "$got" == "644" ]]
