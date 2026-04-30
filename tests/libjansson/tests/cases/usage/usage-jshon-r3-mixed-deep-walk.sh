#!/usr/bin/env bash
# @testcase: usage-jshon-r3-mixed-deep-walk
# @title: jshon walks object then array then object then key
# @description: Drills through an object that holds an array of objects, picks one entry by index, then extracts a leaf string key on the inner object and verifies the unstringed leaf as well as intermediate types.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r3-mixed-deep-walk"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.json" <<'EOF'
{
  "container": [
    {"id": "first", "label": "ignore"},
    {"id": "second", "label": "target-leaf"},
    {"id": "third", "label": "ignore"}
  ]
}
EOF

# Object -> array -> object -> key
jshon -F "$tmpdir/input.json" -e container -e 1 -e label -u >"$tmpdir/leaf"
if ! grep -Fxq -- 'target-leaf' "$tmpdir/leaf"; then
  printf 'expected target-leaf at container[1].label, got:\n' >&2
  cat "$tmpdir/leaf" >&2
  exit 1
fi

# Type at root must be object.
jshon -F "$tmpdir/input.json" -t >"$tmpdir/t-root"
grep -Fxq -- 'object' "$tmpdir/t-root" || {
  printf 'expected object at root, got:\n' >&2
  cat "$tmpdir/t-root" >&2
  exit 1
}

# Type at container must be array.
jshon -F "$tmpdir/input.json" -e container -t >"$tmpdir/t-container"
grep -Fxq -- 'array' "$tmpdir/t-container" || {
  printf 'expected array at container, got:\n' >&2
  cat "$tmpdir/t-container" >&2
  exit 1
}

# Type at container[1] must be object.
jshon -F "$tmpdir/input.json" -e container -e 1 -t >"$tmpdir/t-elem"
grep -Fxq -- 'object' "$tmpdir/t-elem" || {
  printf 'expected object at container[1], got:\n' >&2
  cat "$tmpdir/t-elem" >&2
  exit 1
}

# Type at container[1].label must be string.
jshon -F "$tmpdir/input.json" -e container -e 1 -e label -t >"$tmpdir/t-leaf"
grep -Fxq -- 'string' "$tmpdir/t-leaf" || {
  printf 'expected string at leaf, got:\n' >&2
  cat "$tmpdir/t-leaf" >&2
  exit 1
}
