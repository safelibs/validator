#!/usr/bin/env bash
# @testcase: usage-jshon-r5-deep-mixed-types-per-index
# @title: jshon -t on each json type within a deeply nested array
# @description: Walks into a deeply nested mixed-type array and queries jshon -t at each index, verifying that string, number, bool, null, array, and object are all reported correctly within the same document.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-deep-mixed-types-per-index"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Path: root.outer.inner is an array of 6 mixed-type entries.
cat >"$tmpdir/input.json" <<'EOF'
{
  "outer": {
    "inner": [
      "text",
      42,
      true,
      null,
      [1, 2, 3],
      {"nested-key": "nested-val"}
    ]
  }
}
EOF

declare -a expected=(string number bool null array object)
for idx in 0 1 2 3 4 5; do
  jshon -F "$tmpdir/input.json" -e outer -e inner -e "$idx" -t >"$tmpdir/type-$idx"
  want=${expected[$idx]}
  if ! grep -Fxq -- "$want" "$tmpdir/type-$idx"; then
    printf 'expected type %s at outer.inner[%s], got:\n' "$want" "$idx" >&2
    cat "$tmpdir/type-$idx" >&2
    exit 1
  fi
done
