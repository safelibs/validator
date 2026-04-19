#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <json-c/json.h>
#include <stdio.h>
int main(void){enum json_tokener_error e;json_object*o=json_tokener_parse_verbose("{\"name\":\"alpha\",\"items\":[1,2]}",&e);if(!o)return 1;json_object*n;json_object_object_get_ex(o,"name",&n);printf("name=%s\n",json_object_get_string(n));json_object_put(o);return e==json_tokener_success?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs json-c); "$tmpdir/t"
