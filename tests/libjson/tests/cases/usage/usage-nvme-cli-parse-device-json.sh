#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    cat >"$tmpdir/t.c" <<'C'
#include <json-c/json.h>
#include <stdio.h>
int main(void) { json_object *r=json_tokener_parse("{\"Devices\":[{\"NameSpace\":1}]}"); if(!r) return 1; json_object *v=NULL; if(!json_object_object_get_ex(r,"Devices",&v)) return 2; printf("Devices=%s\n", json_object_to_json_string_ext(v, JSON_C_TO_STRING_PLAIN)); json_object_put(r); return 0; }
C
    gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs json-c)
    "$tmpdir/t"
