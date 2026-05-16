#!/usr/bin/env bash
# @testcase: usage-jshon-r21-insert-empty-array-then-keys
# @title: jshon -n "[]" -i empty creates an empty-array entry observable via -k
# @description: Starts from an empty JSON object {}, pipes it through jshon -n "[]" -i empty -k to insert an empty array under key "empty" and then list the parent keys, asserts the captured single-line output equals exactly "empty" - locking in libjansson-backed jshon's pipeline for inserting a fresh empty array into an empty object via the -n container literal.
# @timeout: 30
# @tags: usage, json, cli, insert, empty-array, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{}' | jshon -n '[]' -i empty -k >"$tmpdir/out"
mapfile -t lines <"$tmpdir/out"
[[ "${#lines[@]}" -eq 1 ]] || { printf 'expected 1 key, got %s\n' "${#lines[@]}" >&2; cat "$tmpdir/out" >&2; exit 1; }
[[ "${lines[0]}" == "empty" ]] || { printf 'expected empty, got %q\n' "${lines[0]}" >&2; exit 1; }
