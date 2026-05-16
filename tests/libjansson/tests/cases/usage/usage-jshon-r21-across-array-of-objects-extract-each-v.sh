#!/usr/bin/env bash
# @testcase: usage-jshon-r21-across-array-of-objects-extract-each-v
# @title: jshon -a -e v -u emits the v field of each object in an array on separate lines
# @description: Pipes a JSON array of three objects each carrying a numeric "v" field through jshon -a -e v -u and asserts the captured output consists of exactly three lines with the values "10", "20", "30" in that order - locking in libjansson-backed jshon's across-then-extract pipeline that iterates an array and projects a per-element field.
# @timeout: 30
# @tags: usage, json, cli, across, array-of-objects, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[{"v":10},{"v":20},{"v":30}]' | jshon -a -e v -u >"$tmpdir/out"
mapfile -t lines <"$tmpdir/out"
[[ "${#lines[@]}" -eq 3 ]] || { printf 'expected 3 lines, got %s\n' "${#lines[@]}" >&2; cat "$tmpdir/out" >&2; exit 1; }
[[ "${lines[0]}" == "10" ]] || { printf 'line 1: %q\n' "${lines[0]}" >&2; exit 1; }
[[ "${lines[1]}" == "20" ]] || { printf 'line 2: %q\n' "${lines[1]}" >&2; exit 1; }
[[ "${lines[2]}" == "30" ]] || { printf 'line 3: %q\n' "${lines[2]}" >&2; exit 1; }
