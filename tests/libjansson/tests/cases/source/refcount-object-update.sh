#!/usr/bin/env bash
# @testcase: refcount-object-update
# @title: Jansson refcount object update
# @description: Replaces object members while holding an extra reference to validate lifetime behavior.
# @timeout: 120
# @tags: api, refcount

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="refcount-object-update"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local source=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs jansson)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$source"
}

compile_and_run 'held=first current=second' <<'C'
#include <jansson.h>
#include <stdio.h>
int main(void) {
    json_t *root = json_object();
    json_t *held = json_string("first");
    json_object_set_new(root, "value", held);
    json_incref(held);
    json_object_set_new(root, "value", json_string("second"));
    printf("held=%s current=%s\n", json_string_value(held), json_string_value(json_object_get(root, "value")));
    json_decref(held);
    json_decref(root);
    return 0;
}
C
