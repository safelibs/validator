#!/usr/bin/env bash
# @testcase: usage-jshon-r20-across-types-of-mixed-array-elements
# @title: jshon -a -t reports the four element types of a mixed-type array
# @description: Pipes [true,1,"x",null] through jshon -a -t and asserts the four output lines are exactly "bool", "number", "string", "null" in order, exercising libjansson's value-type enumeration via jshon's across-map and type-name reporting on a four-element mixed array.
# @timeout: 30
# @tags: usage, json, cli, array, across, type, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '[true,1,"x",null]' | jshon -a -t >"$tmpdir/types.txt"
mapfile -t types <"$tmpdir/types.txt"
[[ "${#types[@]}" -eq 4 ]] || { printf 'expected 4 lines, got %s\n' "${#types[@]}" >&2; cat "$tmpdir/types.txt" >&2; exit 1; }
[[ "${types[0]}" == "bool"   ]] || { printf '0=%s\n' "${types[0]}" >&2; exit 1; }
[[ "${types[1]}" == "number" ]] || { printf '1=%s\n' "${types[1]}" >&2; exit 1; }
[[ "${types[2]}" == "string" ]] || { printf '2=%s\n' "${types[2]}" >&2; exit 1; }
[[ "${types[3]}" == "null"   ]] || { printf '3=%s\n' "${types[3]}" >&2; exit 1; }
