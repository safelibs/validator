#!/usr/bin/env bash
# @testcase: usage-jshon-escaped-slash-string
# @title: jshon escaped slash string
# @description: Exercises jshon escaped slash string through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-escaped-slash-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"name":"demo","count":7,"ratio":1.5,"items":[1,2,3],"records":[{"name":"alpha"},{"name":"beta"}],"nested":{"empty":[],"child":{"label":"ok"}}}'
run_jshon() {
  printf '%s' "$1" | jshon "${@:2}" >"$tmpdir/out"
}

run_jshon '{"path":"alpha\\/beta"}' -e path -u
grep -Fxq 'alpha\/beta' "$tmpdir/out"
