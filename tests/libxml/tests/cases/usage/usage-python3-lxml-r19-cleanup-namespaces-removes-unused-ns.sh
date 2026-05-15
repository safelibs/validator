#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r19-cleanup-namespaces-removes-unused-ns
# @title: lxml etree.cleanup_namespaces removes an unused namespace declaration from the tree
# @description: Builds a tree where the root declares two namespaces but only one is actually used, calls etree.cleanup_namespaces(tree), and asserts the serialized output drops the unused namespace while keeping the in-use one.
# @timeout: 60
# @tags: usage, xml, python, namespaces, cleanup, r19
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.fromstring(b'<r xmlns:keep="urn:keep" xmlns:drop="urn:drop"><keep:leaf/></r>')
etree.cleanup_namespaces(root)
print('xml=' + etree.tostring(root).decode('ascii'))
PY

grep -Fq 'xmlns:keep="urn:keep"' "$tmpdir/out"
if grep -Fq 'urn:drop' "$tmpdir/out"; then
    echo "expected unused namespace urn:drop to be removed" >&2
    cat "$tmpdir/out" >&2
    exit 1
fi
