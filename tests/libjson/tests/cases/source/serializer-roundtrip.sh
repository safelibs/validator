#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <json-c/json.h>
#include <stdio.h>
int main(void){json_object*o=json_object_new_object();json_object_object_add(o,"answer",json_object_new_int(42));const char*s=json_object_to_json_string_ext(o,JSON_C_TO_STRING_PLAIN);puts(s);json_object*a=json_tokener_parse(s);json_object*v;json_object_object_get_ex(a,"answer",&v);int ok=v&&json_object_get_int(v)==42;json_object_put(a);json_object_put(o);return ok?0:1;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs json-c); "$tmpdir/t"
