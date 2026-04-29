#!/usr/bin/env bash
# @testcase: pack-unpack-values
# @title: Jansson pack and unpack values
# @description: Builds JSON with json_pack and reads typed members back with json_unpack.
# @timeout: 120
# @tags: api, object

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="pack-unpack-values"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local source=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs jansson)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$source"
}

compile_and_run 'name=alpha count=7' <<'C'
#include <jansson.h>
#include <stdio.h>
int main(void) {
    json_t *root = json_pack("{s:s,s:i}", "name", "alpha", "count", 7);
    const char *name = NULL;
    int count = 0;
    if (json_unpack(root, "{s:s,s:i}", "name", &name, "count", &count) != 0) return 1;
    printf("name=%s count=%d\n", name, count);
    json_decref(root);
    return count == 7 ? 0 : 2;
}
C
