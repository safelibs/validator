#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r21-format-indent-tab-flag
# @title: xmlstarlet fo --indent-tab emits tab-prefixed nested element lines
# @description: Runs xmlstarlet fo --indent-tab on a flat single-line XML document, then asserts the output contains at least one nested-element line that starts with a tab character — pinning xmlstarlet's libxml2-backed pretty-printer's tab-indent mode on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, xmlstarlet, format, indent-tab, r21
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root><a><b>x</b></a></root>
XML

xmlstarlet fo --indent-tab "$tmpdir/in.xml" >"$tmpdir/out.xml"
[[ -s "$tmpdir/out.xml" ]]
# Expect at least one tab-indented line.
grep -Pq '^\t' "$tmpdir/out.xml" || { echo "expected tab-prefixed indent line" >&2; cat -A "$tmpdir/out.xml" >&2; exit 1; }
