#!/usr/bin/env bash
# @testcase: usage-gio-r12-info-unix-uid-attribute
# @title: gio info exposes unix::uid attribute as an unsigned integer
# @description: Creates a file and asserts gio info -a unix::uid prints a unix::uid attribute whose value parses as a non-negative integer matching the file owner uid.
# @timeout: 60
# @tags: usage, gio, info, unix
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "owner" >"$tmpdir/file.txt"
expected=$(stat -c '%u' "$tmpdir/file.txt")
gio info -a unix::uid "$tmpdir/file.txt" >"$tmpdir/out"
value=$(awk -F': ' '/^  unix::uid:/ {print $2; exit}' "$tmpdir/out")
[[ -n "$value" ]] || { sed -n '1,40p' "$tmpdir/out" >&2; exit 1; }
[[ "$value" =~ ^[0-9]+$ ]] || { echo "non-numeric uid: $value" >&2; exit 1; }
[[ "$value" = "$expected" ]] || { echo "uid mismatch: got $value want $expected" >&2; exit 1; }
