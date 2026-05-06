#!/usr/bin/env bash
# @testcase: usage-jshon-r11-sort-recurses-into-nested-objects
# @title: jshon -S sorts keys recursively in nested objects
# @description: Feeds a two-level object whose top-level and inner keys are both scrambled, and verifies jshon -S returns both layers with keys in lexicographic order.
# @timeout: 60
# @tags: usage, json, cli, sort
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"z":{"b":1,"a":2,"c":3},"a":1,"m":{"y":1,"x":2}}' | jshon -S >"$tmpdir/sorted.json"

top_keys=$(jshon -F "$tmpdir/sorted.json" -k | tr '\n' ' ')
[[ "$top_keys" == "a m z " ]] || { printf 'expected top keys "a m z ", got %q\n' "$top_keys" >&2; exit 1; }

z_keys=$(jshon -F "$tmpdir/sorted.json" -e z -k | tr '\n' ' ')
[[ "$z_keys" == "a b c " ]] || { printf 'expected nested z keys "a b c ", got %q\n' "$z_keys" >&2; exit 1; }

m_keys=$(jshon -F "$tmpdir/sorted.json" -e m -k | tr '\n' ' ')
[[ "$m_keys" == "x y " ]] || { printf 'expected nested m keys "x y ", got %q\n' "$m_keys" >&2; exit 1; }
