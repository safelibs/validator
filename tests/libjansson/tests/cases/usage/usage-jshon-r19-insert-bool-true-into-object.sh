#!/usr/bin/env bash
# @testcase: usage-jshon-r19-insert-bool-true-into-object
# @title: jshon -n true -i flag inserts a JSON boolean and extracts it as type bool
# @description: Starts with empty object {}, inserts the JSON boolean true under key "flag" via jshon -n true -i flag, then runs -e flag -t and asserts stdout equals "bool" exactly, exercising libjansson's boolean insert-into-object path through jshon's -n raw-JSON insertion.
# @timeout: 30
# @tags: usage, json, cli, insert, bool, true, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

mod=$(printf '{}' | jshon -n true -i flag)
type=$(printf '%s' "$mod" | jshon -e flag -t)
if [[ "$type" != 'bool' ]]; then
  printf 'expected bool, got %s\n' "$type" >&2
  exit 1
fi
val=$(printf '%s' "$mod" | jshon -e flag -u)
if [[ "$val" != 'true' ]]; then
  printf 'expected true, got %s\n' "$val" >&2
  exit 1
fi
