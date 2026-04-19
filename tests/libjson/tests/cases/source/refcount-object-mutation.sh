#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <json-c/json.h>
#include <stdio.h>
int main(void){json_object*c=json_object_new_string("first");json_object_get(c);json_object*o=json_object_new_object();json_object_object_add(o,"child",c);json_object_object_add(o,"child",json_object_new_string("second"));printf("held=%s object=%s\n",json_object_get_string(c),json_object_to_json_string(o));json_object_put(c);json_object_put(o);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs json-c); "$tmpdir/t"
