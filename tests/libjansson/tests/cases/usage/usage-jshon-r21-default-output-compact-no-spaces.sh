#!/usr/bin/env bash
# @testcase: usage-jshon-r21-default-output-compact-no-spaces
# @title: jshon default output of a single-key object emits one space after the colon per line
# @description: Pipes the JSON object {"k":1} through jshon (no flags) and asserts the captured output exactly equals the three-line representation "{\n \"k\": 1\n}\n" - locking in libjansson-backed jshon's default reformatting output: keys indented by a single space, a colon-space delimiter between key and value, and braces on their own lines.
# @timeout: 30
# @tags: usage, json, cli, default-output, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"k":1}' | jshon >"$tmpdir/out"

# Build expected bytes deterministically.
{
    printf '{\n'
    printf ' "k": 1\n'
    printf '}\n'
} >"$tmpdir/exp"

cmp -s "$tmpdir/out" "$tmpdir/exp" || {
    echo 'unexpected default output bytes' >&2
    od -c "$tmpdir/out" >&2
    echo --expected-- >&2
    od -c "$tmpdir/exp" >&2
    exit 1
}
