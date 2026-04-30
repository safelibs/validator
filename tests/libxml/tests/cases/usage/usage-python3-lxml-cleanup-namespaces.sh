#!/usr/bin/env bash
# @testcase: usage-python3-lxml-cleanup-namespaces
# @title: lxml cleanup_namespaces removes unused namespaces
# @description: Builds an XML tree with several namespace declarations on the root, only one of which is actually used by a child, then runs etree.cleanup_namespaces and verifies the unused declarations are stripped from the serialized output while the used namespace is preserved.
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

before = etree.tostring(root, encoding='unicode')
assert 'urn:a' in before and 'urn:b' in before and 'urn:c' in before, before

etree.cleanup_namespaces(root)
after = etree.tostring(root, encoding='unicode')

# Only the used a-namespace must survive.
assert 'urn:a' in after, after
assert 'urn:b' not in after, after
assert 'urn:c' not in after, after

print("before=" + before)
print("after=" + after)
PY

validator_assert_contains "$tmpdir/out" 'before=<root'
validator_assert_contains "$tmpdir/out" 'xmlns:b="urn:b"'
validator_assert_contains "$tmpdir/out" 'xmlns:c="urn:c"'
validator_assert_contains "$tmpdir/out" 'after='
# Strict assertion: the cleaned tree no longer mentions urn:b or urn:c.
if grep -E '^after=.*urn:b' "$tmpdir/out" >/dev/null; then
  printf 'cleanup_namespaces left urn:b on the output\n' >&2
  exit 1
fi
if grep -E '^after=.*urn:c' "$tmpdir/out" >/dev/null; then
  printf 'cleanup_namespaces left urn:c on the output\n' >&2
  exit 1
fi
