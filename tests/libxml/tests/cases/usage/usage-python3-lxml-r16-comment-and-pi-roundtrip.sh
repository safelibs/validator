#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r16-comment-and-pi-roundtrip
# @title: lxml etree.Comment and etree.ProcessingInstruction nodes appended to a tree survive tostring round-trip
# @description: Appends an etree.Comment and an etree.ProcessingInstruction to an element, serializes via tostring, parses the result, and asserts the comment text and PI target/data come back identically — confirming both node types survive a serialize/parse cycle.
# @timeout: 60
# @tags: usage, xml, python, comment, pi
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.Element('root')
root.append(etree.Comment(' r16-comment '))
root.append(etree.ProcessingInstruction('do', 'arg=1'))
root.append(etree.SubElement(root, 'leaf'))

serialized = etree.tostring(root)
print('serialized=' + serialized.decode())

parsed = etree.fromstring(serialized)
comments = [c for c in parsed.iter() if isinstance(c.tag, str) is False or callable(c.tag)]
# Lxml exposes comment nodes via etree.Comment as their .tag function.
c_nodes = [c for c in parsed.iter(etree.Comment)]
p_nodes = [p for p in parsed.iter(etree.ProcessingInstruction)]
print('comment_count=' + str(len(c_nodes)))
print('comment_text=' + c_nodes[0].text)
print('pi_count=' + str(len(p_nodes)))
print('pi_target=' + p_nodes[0].target)
print('pi_text=' + p_nodes[0].text)
PY

validator_assert_contains "$tmpdir/out" 'comment_count=1'
validator_assert_contains "$tmpdir/out" 'comment_text= r16-comment '
validator_assert_contains "$tmpdir/out" 'pi_count=1'
validator_assert_contains "$tmpdir/out" 'pi_target=do'
validator_assert_contains "$tmpdir/out" 'pi_text=arg=1'
