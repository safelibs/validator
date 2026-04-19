#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <cjson/cJSON.h>
#include <stdio.h>
#include <string.h>
int main(void){char s[]=" { \n \"name\" : \"value with spaces\", \"items\" : [ 1 , 2 ] } ";cJSON_Minify(s);puts(s);return strcmp(s,"{\"name\":\"value with spaces\",\"items\":[1,2]}");}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcjson
"$tmpdir/t"
