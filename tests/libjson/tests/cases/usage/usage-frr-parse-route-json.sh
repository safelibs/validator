#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    cat >"$tmpdir/t.c" <<'C'
#include <json-c/json.h>
#include <stdio.h>
int main(void) { json_object *r=json_tokener_parse("{\"routes\":[{\"prefix\":\"127.0.0.0/8\"}]}"); if(!r) return 1; json_object *v=NULL; if(!json_object_object_get_ex(r,"routes",&v)) return 2; printf("routes=%s\n", json_object_to_json_string_ext(v, JSON_C_TO_STRING_PLAIN)); json_object_put(r); return 0; }
C
    gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs json-c)
    "$tmpdir/t"
