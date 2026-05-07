#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r13-pyx-roundtrip-counts
# @title: xmlstarlet pyx emits one PYX line per element open, attribute, text, and close
# @description: Runs xmlstarlet pyx on a small two-item XML document and asserts the emitted PYX stream contains the expected open-tag "(", attribute "A", text "-", and close-tag ")" line counts that match a hand-derived analysis of the input.
# @timeout: 60
# @tags: usage, xmlstarlet, pyx
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item id="1">alpha</item>
  <item id="2">beta</item>
</root>
XML

xmlstarlet pyx "$tmpdir/in.xml" >"$tmpdir/out.pyx"

# 3 open tags: root + 2 item.
opens=$(grep -c '^(' "$tmpdir/out.pyx")
[[ "$opens" == "3" ]] || { printf 'expected 3 open tags, got %s\n' "$opens" >&2; cat "$tmpdir/out.pyx" >&2; exit 1; }

# 3 close tags.
closes=$(grep -c '^)' "$tmpdir/out.pyx")
[[ "$closes" == "3" ]] || { printf 'expected 3 close tags, got %s\n' "$closes" >&2; cat "$tmpdir/out.pyx" >&2; exit 1; }

# 2 id attributes - one per item.
attrs=$(grep -c '^Aid ' "$tmpdir/out.pyx")
[[ "$attrs" == "2" ]] || { printf 'expected 2 id attributes, got %s\n' "$attrs" >&2; cat "$tmpdir/out.pyx" >&2; exit 1; }

# Each item text appears as a PYX text record (prefixed with -).
grep -q '^-alpha' "$tmpdir/out.pyx"
grep -q '^-beta' "$tmpdir/out.pyx"
