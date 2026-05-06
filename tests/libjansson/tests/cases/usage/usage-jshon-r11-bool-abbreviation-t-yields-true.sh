#!/usr/bin/env bash
# @testcase: usage-jshon-r11-bool-abbreviation-t-yields-true
# @title: jshon -n t inserts a JSON true value
# @description: Uses the documented one-character abbreviation -n t (and -n f) to insert booleans into an object; verifies both keys round-trip with the bool type and the unstring values true/false.
# @timeout: 30
# @tags: usage, json, cli, bool
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{}' | jshon -n t -i flag_t -n f -i flag_f)

t_type=$(printf '%s' "$result" | jshon -e flag_t -t)
[[ "$t_type" == "bool" ]] || { printf 'expected bool, got %s\n' "$t_type" >&2; exit 1; }
f_type=$(printf '%s' "$result" | jshon -e flag_f -t)
[[ "$f_type" == "bool" ]] || { printf 'expected bool, got %s\n' "$f_type" >&2; exit 1; }

t_val=$(printf '%s' "$result" | jshon -e flag_t -u)
[[ "$t_val" == "true" ]] || { printf 'expected true, got %s\n' "$t_val" >&2; exit 1; }
f_val=$(printf '%s' "$result" | jshon -e flag_f -u)
[[ "$f_val" == "false" ]] || { printf 'expected false, got %s\n' "$f_val" >&2; exit 1; }
