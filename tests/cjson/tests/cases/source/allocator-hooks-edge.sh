#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <cjson/cJSON.h>
#include <stdio.h>
#include <stdlib.h>
static int a,f; static void*m(size_t n){a++;return malloc(n);} static void r(void*p){if(p)f++;free(p);} int main(void){cJSON_Hooks h={m,r};cJSON_InitHooks(&h);cJSON*j=cJSON_Parse("{\"array\":[true,false,null,42]}");if(!j)return 1;char*s=cJSON_PrintUnformatted(j);puts(s);cJSON_free(s);cJSON_Delete(j);cJSON_InitHooks(NULL);printf("allocations=%d frees=%d\n",a,f);return a>0&&f>0?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcjson
"$tmpdir/t"
