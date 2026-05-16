#!/usr/bin/env bash
# @testcase: usage-bash-r21-indirect-expansion-resolves-var
# @title: bash ${!name} indirect expansion resolves a variable by name
# @description: Sets variable foo=bar and pointer=foo, then asserts ${!pointer} expands to "bar" - locking in the bash indirect-variable-reference operator, a code path not exercised by existing param-expansion tests (default/replace/trim).
# @timeout: 30
# @tags: usage, bash, indirect-expansion, r21
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(bash -c 'foo=bar; pointer=foo; printf "%s" "${!pointer}"')
[[ "$got" == "bar" ]] || {
    printf 'expected "bar", got %q\n' "$got" >&2
    exit 1
}
