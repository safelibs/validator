#!/usr/bin/env bash
# @testcase: usage-jshon-r6-roundtrip-formatting-stable
# @title: jshon round-trip emits stable canonical formatting
# @description: Feeds the same JSON document through jshon twice using two different input whitespace shapes (compact and pretty-printed with newlines and tabs) and verifies that the two normalized outputs are byte-for-byte identical. jshon's emit format does not preserve original whitespace, but it must be deterministic across whitespace variants of the same logical document.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-roundtrip-formatting-stable"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Two whitespace shapes for the SAME logical document.
compact='{"name":"alpha","values":[1,2,3],"active":true}'

cat >"$tmpdir/pretty.json" <<'EOF'
{
	"name" : "alpha",
	"values" : [
		1,
		2,
		3
	],
	"active" : true
}
EOF

# Echo the document through jshon (no edits) to obtain the canonical form.
printf '%s' "$compact" | jshon >"$tmpdir/canon-compact"
jshon -F "$tmpdir/pretty.json" >"$tmpdir/canon-pretty"

# Both files must be non-empty.
test -s "$tmpdir/canon-compact"
test -s "$tmpdir/canon-pretty"

# Canonicalized outputs must be byte-identical regardless of input whitespace.
if ! diff -u "$tmpdir/canon-compact" "$tmpdir/canon-pretty" >"$tmpdir/diff"; then
  printf 'expected identical canonical output for whitespace-only variants, diff:\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
fi

# Re-feeding the canonical form yields the same canonical form again (idempotent).
jshon <"$tmpdir/canon-compact" >"$tmpdir/canon-second"
if ! diff -u "$tmpdir/canon-compact" "$tmpdir/canon-second" >"$tmpdir/diff2"; then
  printf 'expected jshon canonical form to be idempotent, diff:\n' >&2
  cat "$tmpdir/diff2" >&2
  exit 1
fi

# Logical content survives: -e values -l on the canonical form still reports 3.
jshon -F "$tmpdir/canon-compact" -e values -l >"$tmpdir/vlen"
if ! grep -Fxq -- '3' "$tmpdir/vlen"; then
  printf 'expected values length 3 in canonical form, got:\n' >&2
  cat "$tmpdir/vlen" >&2
  exit 1
fi
