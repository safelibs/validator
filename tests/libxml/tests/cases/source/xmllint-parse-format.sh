#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '<root><item id="1">alpha</item></root>\n' >"$tmpdir/in.xml"; xmllint --noout "$tmpdir/in.xml"; xmllint --format "$tmpdir/in.xml" | tee "$tmpdir/f.xml"; grep '<item id="1">alpha</item>' "$tmpdir/f.xml"
