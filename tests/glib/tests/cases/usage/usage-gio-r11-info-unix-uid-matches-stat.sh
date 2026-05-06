#!/usr/bin/env bash
# @testcase: usage-gio-r11-info-unix-uid-matches-stat
# @title: gio info unix::uid attribute equals stat -c %u
# @description: Creates a regular file and verifies that "gio info -a unix::uid" reports the same numeric uid that "stat -c %u" reports for the same path.
# @timeout: 60
# @tags: usage, gio, info, unix
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "owned by current user" >"$tmpdir/x"
gio info -a unix::uid "$tmpdir/x" >"$tmpdir/out"
gio_uid=$(awk -F': ' '/^  unix::uid:/ {print $2; exit}' "$tmpdir/out")
stat_uid=$(stat -c '%u' "$tmpdir/x")
[[ -n "$gio_uid" ]] || { sed -n '1,40p' "$tmpdir/out" >&2; exit 1; }
[[ "$gio_uid" == "$stat_uid" ]] || { printf 'gio=%s stat=%s\n' "$gio_uid" "$stat_uid" >&2; exit 1; }
