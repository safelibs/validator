#!/usr/bin/env bash
# @testcase: usage-jshon-r7-type-survey-across-shapes
# @title: jshon -t reports the canonical label for every JSON shape via -F
# @description: Wraps each scalar/container shape inside a one-element array document, then descends with jshon -F file -e 0 -t and asserts the type label printed for object, array, string, integer number, fractional number, true bool, false bool, and null all match the expected jshon vocabulary.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r7-type-survey-across-shapes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_doc() {
  local name=$1 inner=$2
  printf '[%s]' "$inner" >"$tmpdir/$name.json"
}

write_doc obj   '{"k":1}'
write_doc arr   '[1,2,3]'
write_doc str   '"hello"'
write_doc int   '42'
write_doc frac  '3.14'
write_doc bt    'true'
write_doc bf    'false'
write_doc nl    'null'

probe() {
  local name=$1 expected=$2
  jshon -F "$tmpdir/$name.json" -e 0 -t >"$tmpdir/t-$name"
  if ! grep -Fxq -- "$expected" "$tmpdir/t-$name"; then
    printf 'expected type %s for %s.json, got:\n' "$expected" "$name" >&2
    cat "$tmpdir/t-$name" >&2
    exit 1
  fi
}

probe obj  object
probe arr  array
probe str  string
probe int  number
probe frac number
probe bt   bool
probe bf   bool
probe nl   null
