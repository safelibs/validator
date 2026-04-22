#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local source=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs jansson)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$source"
}

case "$case_id" in
  object-dump-roundtrip)
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
    ;;
  array-iteration-sum)
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
    ;;
  pack-unpack-values)
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
    ;;
  refcount-object-update)
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
    ;;
  malformed-json-error)
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
    ;;
  *)
    printf 'unknown libjansson source case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
