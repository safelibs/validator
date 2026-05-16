#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r21-iterparse-pi-event
# @title: lxml iterparse with events=('pi',) yields processing-instruction nodes with their targets
# @description: Parses a document containing two processing instructions through lxml.etree.iterparse(events=('pi',)) and asserts the iterator yields two pi events whose .target values match the source targets in document order — pinning lxml's libxml2 PI event surface.
# @timeout: 60
# @tags: usage, xml, python, iterparse, pi, r21
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import io
from lxml import etree

src = b'<?xml version="1.0"?><r><?do thing?><a/><?stop now?></r>'
events = list(etree.iterparse(io.BytesIO(src), events=('pi',)))
assert len(events) == 2, events
targets = [e[1].target for e in events]
assert targets == ['do', 'stop'], targets
for ev, node in events:
    assert ev == 'pi', ev
PY
