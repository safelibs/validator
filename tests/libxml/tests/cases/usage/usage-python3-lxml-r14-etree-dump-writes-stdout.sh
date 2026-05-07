#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r14-etree-dump-writes-stdout
# @title: lxml etree.dump writes the indented serialization of an Element to stdout
# @description: Calls etree.dump on a small Element with nested children, redirects the python process stdout to a file, and asserts the captured output is the indented XML representation of the element with the parent and child tags both present.
# @timeout: 60
# @tags: usage, xml, python, dump
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' >"$tmpdir/dump.out" 2>"$tmpdir/dump.err"
from lxml import etree
e = etree.fromstring(b'<root><leaf>r14</leaf></root>')
etree.dump(e)
PY

validator_assert_contains "$tmpdir/dump.out" '<root>'
validator_assert_contains "$tmpdir/dump.out" '<leaf>r14</leaf>'
validator_assert_contains "$tmpdir/dump.out" '</root>'

# stderr must not have received the dump output.
if [[ -s "$tmpdir/dump.err" ]]; then
    printf 'unexpected stderr from etree.dump:\n' >&2
    cat "$tmpdir/dump.err" >&2
    exit 1
fi
