#!/usr/bin/env bash
# @testcase: array-iteration-sum
# @title: Jansson array iteration sum
# @description: Iterates numeric array elements through the public API and verifies their sum.
# @timeout: 120
# @tags: api, array

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="array-iteration-sum"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local source=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs jansson)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$source"
}

compile_and_run 'sum=10' <<'C'
#include <jansson.h>
#include <stdio.h>
int main(void) {
    json_t *array = json_pack("[i,i,i,i]", 1, 2, 3, 4);
    size_t index;
    json_t *value;
    int sum = 0;
    json_array_foreach(array, index, value) {
        sum += (int)json_integer_value(value);
    }
    printf("sum=%d\n", sum);
    json_decref(array);
    return sum == 10 ? 0 : 1;
}
C
