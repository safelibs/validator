#!/usr/bin/env bash
# @testcase: usage-jshon-r19-unicode-key-extract-value
# @title: jshon -e on a key with a Unicode escape returns the expected string value
# @description: Pipes {"étoile":"star"} through jshon -e $'étoile' -u and asserts the unwrapped result equals "star" exactly, exercising libjansson's parsing of \u escapes in object keys followed by jshon's UTF-8 key lookup on the resulting in-memory object.
# @timeout: 30
# @tags: usage, json, cli, unicode, escape, key, r19
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

# Use printf to emit a UTF-8 "etoile" literal as the lookup key.
key=$(printf '\xc3\xa9toile')
out=$(printf '{"\\u00e9toile":"star"}' | jshon -e "$key" -u)
if [[ "$out" != 'star' ]]; then
  printf 'expected star, got %s\n' "$out" >&2
  exit 1
fi
