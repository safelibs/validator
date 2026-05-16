#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r21-iterparse-comment-event
# @title: lxml iterparse with events=('comment',) yields exactly the comment nodes in document order
# @description: Feeds a small document containing two comments interleaved with elements to lxml.etree.iterparse(events=('comment',)) and asserts the iterator yields exactly two ('comment', <node>) tuples whose text content matches the source comments — pinning lxml's libxml2-backed comment event emission.
# @timeout: 60
# @tags: usage, xml, python, iterparse, comment, r21
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import io
from lxml import etree

src = b'<r><!-- alpha --><a/><!-- beta --><b/></r>'
events = list(etree.iterparse(io.BytesIO(src), events=('comment',)))
assert len(events) == 2, events
texts = [e[1].text.strip() for e in events]
assert texts == ['alpha', 'beta'], texts
for ev, node in events:
    assert ev == 'comment', ev
PY
