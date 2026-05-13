#!/usr/bin/env bash
# @testcase: usage-coreutils-r16-cut-output-delimiter-pipe
# @title: cut --output-delimiter rewrites the field separator on output
# @description: Pipes a comma-delimited single line into cut -d, -f1,3 --output-delimiter='|' and asserts the result joins the selected fields with a pipe rather than a comma, locking in the GNU --output-delimiter rewrite that splits the read/write delimiter.
# @timeout: 30
# @tags: usage, coreutils, cut, delimiter
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

out=$(printf 'a,b,c,d\n' | cut -d, -f1,3 --output-delimiter='|')
[[ "$out" == "a|c" ]] || {
    printf 'expected "a|c", got %q\n' "$out" >&2
    exit 1
}
