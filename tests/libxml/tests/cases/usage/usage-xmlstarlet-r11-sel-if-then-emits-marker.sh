#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r11-sel-if-then-emits-marker
# @title: xmlstarlet sel -i predicate emits the documented YES/NO marker
# @description: Runs xmlstarlet sel with a -t -i predicate that compares count() against the source tree and asserts a documents-with-match input emits "YES" while a documents-without-match input emits "NO" via mirrored if/elif templates.
# @timeout: 60
# @tags: usage, xmlstarlet, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/with.xml" <<'XML'
<r><a/></r>
XML

cat >"$tmpdir/without.xml" <<'XML'
<r/>
XML

xmlstarlet sel -t -i 'count(/r/a) > 0' -o 'YES' -b -n "$tmpdir/with.xml" >"$tmpdir/yes.out"
xmlstarlet sel -t -i 'count(/r/a) = 0' -o 'NO' -b -n "$tmpdir/without.xml" >"$tmpdir/no.out"

actual_yes=$(cat "$tmpdir/yes.out")
actual_no=$(cat "$tmpdir/no.out")
[[ "$actual_yes" == "YES" ]] || { printf 'expected YES, got %q\n' "$actual_yes" >&2; exit 1; }
[[ "$actual_no" == "NO" ]] || { printf 'expected NO, got %q\n' "$actual_no" >&2; exit 1; }
