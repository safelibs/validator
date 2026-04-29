#!/usr/bin/env bash
# @testcase: object-dump-roundtrip
# @title: Jansson object dump round trip
# @description: Parses an object, updates a member, and emits compact sorted JSON.
# @timeout: 120
# @tags: api, json

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="object-dump-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local source=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs jansson)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$source"
}

compile_and_run '"status":"ok"' <<'C'
#include <jansson.h>
#include <stdio.h>
#include <stdlib.h>
int main(void) {
    json_error_t error;
    json_t *root = json_loads("{\"name\":\"demo\",\"count\":2}", 0, &error);
    if (!root) return 1;
    json_object_set_new(root, "status", json_string("ok"));
    char *out = json_dumps(root, JSON_COMPACT | JSON_SORT_KEYS);
    if (!out) return 2;
    puts(out);
    free(out);
    json_decref(root);
    return 0;
}
C
