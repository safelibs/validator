#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r19-sel-template-match-text-extracts-values
# @title: xmlstarlet sel -t -m //item -v . -n prints each item's text on its own line
# @description: Feeds a small XML document with three <item> children to xmlstarlet sel using a -t -m //item template with -v . and -n separator, then asserts the output contains each item's text in document order, exercising the XPath template iteration path.
# @timeout: 60
# @tags: usage, xmlstarlet, sel, template, r19
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<r>
  <item>alpha</item>
  <item>beta</item>
  <item>gamma</item>
</r>
XML

xmlstarlet sel -t -m '//item' -v . -n "$tmpdir/in.xml" >"$tmpdir/out.txt"
# Three lines, in the original order.
mapfile -t lines <"$tmpdir/out.txt"
# Filter out potential blank trailing lines.
filtered=()
for line in "${lines[@]}"; do
    [[ -z "$line" ]] || filtered+=("$line")
done
(( ${#filtered[@]} == 3 )) || { printf 'expected 3 items, got %d\n' "${#filtered[@]}" >&2; cat "$tmpdir/out.txt" >&2; exit 1; }
[[ "${filtered[0]}" == "alpha" ]] || { printf 'unexpected line 0: %q\n' "${filtered[0]}" >&2; exit 1; }
[[ "${filtered[1]}" == "beta" ]] || { printf 'unexpected line 1: %q\n' "${filtered[1]}" >&2; exit 1; }
[[ "${filtered[2]}" == "gamma" ]] || { printf 'unexpected line 2: %q\n' "${filtered[2]}" >&2; exit 1; }
