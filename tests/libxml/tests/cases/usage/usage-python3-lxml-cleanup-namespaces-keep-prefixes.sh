#!/usr/bin/env bash
# @testcase: usage-python3-lxml-cleanup-namespaces-keep-prefixes
# @title: lxml cleanup_namespaces with keep_ns_prefixes
# @description: Calls etree.cleanup_namespaces in-place with the keep_ns_prefixes argument to retain a specified unused namespace declaration on the root, while still pruning a different unused declaration. Verifies the post-cleanup serialization keeps the kept prefix and drops the other.
# @timeout: 180
# @tags: usage, xml, python, namespaces
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xml = (
    '<root xmlns:a="urn:a" xmlns:b="urn:b" xmlns:c="urn:c">'
    '<a:item>X</a:item>'
    '</root>'
)
root = etree.fromstring(xml)

# In-place cleanup that keeps the unused 'b' prefix declaration but drops 'c'.
etree.cleanup_namespaces(root, keep_ns_prefixes=['b'])
after = etree.tostring(root, encoding='unicode')

assert 'urn:a' in after, after
assert 'urn:b' in after, after  # explicitly retained
assert 'urn:c' not in after, after  # pruned

print("after=" + after)
PY

validator_assert_contains "$tmpdir/out" 'after=<root'
validator_assert_contains "$tmpdir/out" 'xmlns:b="urn:b"'
if grep -E '^after=.*urn:c' "$tmpdir/out" >/dev/null; then
  printf 'cleanup_namespaces left urn:c despite not being in keep_ns_prefixes\n' >&2
  exit 1
fi
