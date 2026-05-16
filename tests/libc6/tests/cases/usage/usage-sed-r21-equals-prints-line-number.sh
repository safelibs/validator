#!/usr/bin/env bash
# @testcase: usage-sed-r21-equals-prints-line-number
# @title: sed = command prints the line number before each input line
# @description: Pipes a three-line payload through sed = and asserts the output interleaves the line number ("1", "2", "3") before each source line - locking in the = command's line-number emission distinct from existing -n, address, hold-space, and substitution tests.
# @timeout: 30
# @tags: usage, sed, equals, line-number, r21
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(printf 'alpha\nbeta\ngamma\n' | sed '=')
expected=$'1\nalpha\n2\nbeta\n3\ngamma'
[[ "$got" == "$expected" ]] || {
    printf 'expected:\n%s\n---\ngot:\n%s\n' "$expected" "$got" >&2
    exit 1
}
