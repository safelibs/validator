#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r11-fo-no-indent-flat
# @title: xmlstarlet fo -n strips leading whitespace while keeping line breaks
# @description: Pipes a pre-indented document through xmlstarlet fo -n and asserts the emitted output preserves one element per line while removing the leading per-element indentation, distinguishing -n from the default indenting formatter.
# @timeout: 60
# @tags: usage, xmlstarlet, format
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<r>
    <a>
        <b>x</b>
    </a>
</r>
XML

xmlstarlet fo -n "$tmpdir/in.xml" >"$tmpdir/out"

grep -E '^<a>$' "$tmpdir/out" >/dev/null
grep -E '^<b>x</b>$' "$tmpdir/out" >/dev/null
grep -E '^</r>$' "$tmpdir/out" >/dev/null
if grep -E '^[[:space:]]+<' "$tmpdir/out" >/dev/null; then
    echo "expected no leading-whitespace lines" >&2
    cat "$tmpdir/out" >&2
    exit 1
fi
