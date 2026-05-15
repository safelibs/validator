#!/usr/bin/env bash
# @testcase: usage-jshon-r20-extract-then-sort-keys-alphabetical
# @title: jshon -S -e nested -k emits the nested object keys in alphabetical order
# @description: Pipes an object containing a nested object with three keys defined out-of-order through jshon -S to sort recursively, then extracts the nested object and prints its keys with -k, asserting the keys appear in alphabetical order, exercising libjansson's object representation under jshon's sort and extract chain.
# @timeout: 30
# @tags: usage, json, cli, sort, extract, keys, r20
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"outer":{"zebra":1,"apple":2,"mango":3}}' | jshon -S -e outer -k >"$tmpdir/keys.txt"
mapfile -t lines <"$tmpdir/keys.txt"
[[ "${#lines[@]}" -eq 3 ]] || { printf 'expected 3 keys, got %s\n' "${#lines[@]}" >&2; cat "$tmpdir/keys.txt" >&2; exit 1; }
[[ "${lines[0]}" == "apple" ]] || { printf 'first key %s\n' "${lines[0]}" >&2; exit 1; }
[[ "${lines[1]}" == "mango" ]] || { printf 'second key %s\n' "${lines[1]}" >&2; exit 1; }
[[ "${lines[2]}" == "zebra" ]] || { printf 'third key %s\n' "${lines[2]}" >&2; exit 1; }
