#!/usr/bin/env bash
# @testcase: usage-jshon-nested-object-field
# @title: jshon nested object field
# @description: Exercises jshon nested object field through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-nested-object-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"ratio":1.5,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"empty":[],"child":{"label":"ok"}}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon "$json" -e nested -e child -e label -u
grep -Fxq 'ok' "$tmpdir/out"
