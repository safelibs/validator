#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <json-c/json.h>
#include <stdio.h>
int main(void){enum json_tokener_error e;json_object*o=json_tokener_parse_verbose("{\"missing\":[1,}",&e);if(o)return 1;printf("error=%s\n",json_tokener_error_desc(e));return e==json_tokener_success?2:0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs json-c); "$tmpdir/t"
