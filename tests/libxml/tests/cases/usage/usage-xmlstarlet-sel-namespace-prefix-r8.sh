#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-sel-namespace-prefix-r8
# @title: xmlstarlet sel -N binds custom namespace prefix for XPath
# @description: Selects values out of a namespaced document by binding a prefix via xmlstarlet sel -N to the document's namespace URI, demonstrating that the bound prefix on the command line need not match the document's source prefix and that count/string queries return the expected values.
# @timeout: 120
# @tags: usage, xml, cli, xpath, namespaces, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<a:catalog xmlns:a="urn:cat">
  <a:item id="1">alpha</a:item>
  <a:item id="2">beta</a:item>
  <a:item id="3">gamma</a:item>
</a:catalog>
XML

# Bind a different prefix (k) on the command line, mapped to the same URI.
count=$(xmlstarlet sel -N k=urn:cat -t -v 'count(/k:catalog/k:item)' "$tmpdir/in.xml")
[[ "$count" == "3" ]] || { printf 'expected 3 items, got %s\n' "$count" >&2; exit 1; }

middle=$(xmlstarlet sel -N k=urn:cat -t -v 'string(/k:catalog/k:item[2])' "$tmpdir/in.xml")
[[ "$middle" == "beta" ]] || { printf 'expected beta, got %s\n' "$middle" >&2; exit 1; }

last_id=$(xmlstarlet sel -N k=urn:cat -t -v '/k:catalog/k:item[last()]/@id' "$tmpdir/in.xml")
[[ "$last_id" == "3" ]] || { printf 'expected last id=3, got %s\n' "$last_id" >&2; exit 1; }
