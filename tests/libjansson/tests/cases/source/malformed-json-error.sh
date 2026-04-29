#!/usr/bin/env bash
# @testcase: malformed-json-error
# @title: Jansson malformed JSON error
# @description: Requires json_loads to reject an unterminated array and report a parse location.
# @timeout: 120
# @tags: api, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="malformed-json-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local source=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs jansson)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$source"
}

compile_and_run 'line=1' <<'C'
#include <jansson.h>
#include <stdio.h>
int main(void) {
    json_error_t error;
    json_t *root = json_loads("{\"items\":[1,2,}", 0, &error);
    if (root) return 1;
    printf("line=%d text=%s\n", error.line, error.text);
    return error.line == 1 ? 0 : 2;
}
C
