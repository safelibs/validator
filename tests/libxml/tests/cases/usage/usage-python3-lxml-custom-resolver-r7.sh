#!/usr/bin/env bash
# @testcase: usage-python3-lxml-custom-resolver-r7
# @title: lxml custom URI resolver for entity
# @description: Registers a Resolver subclass on an etree.XMLParser that intercepts an external entity reference using a custom URI scheme and supplies in-memory replacement bytes via resolver.resolve_string(), then parses a document declaring that entity and verifies the parsed text matches the resolver's reply, exercising the libxml2 external entity loader hook.
# @timeout: 120
# @tags: usage, xml, python, parser, resolver
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

calls = []

class ValidatorResolver(etree.Resolver):
    def resolve(self, system_url, public_id, context):
        calls.append(system_url)
        if system_url == "validator://greeting":
            return self.resolve_string("hello-from-resolver", context)
        return None

parser = etree.XMLParser(load_dtd=True, resolve_entities=True, no_network=True)
parser.resolvers.add(ValidatorResolver())

xml = b"""<?xml version="1.0"?>
<!DOCTYPE root [
  <!ENTITY g SYSTEM "validator://greeting">
]>
<root>&g;</root>
"""

doc = etree.fromstring(xml, parser=parser)
text = (doc.text or "").strip()

assert text == "hello-from-resolver", text
assert "validator://greeting" in calls, calls

print("text=" + text)
print("resolver-calls=%d" % len(calls))
PY

validator_assert_contains "$tmpdir/out" 'text=hello-from-resolver'
validator_assert_contains "$tmpdir/out" 'resolver-calls=1'
