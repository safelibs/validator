#!/usr/bin/env bash
# @testcase: utils-patch-pointer
# @title: JSON pointer patch behavior
# @description: Applies a JSON patch and resolves the changed value through cJSON utilities.
# @timeout: 120
# @tags: api, patch

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <cjson/cJSON.h>
#include <cjson/cJSON_Utils.h>
#include <stdio.h>
#include <string.h>
int main(void){cJSON*d=cJSON_Parse("{\"items\":[{\"name\":\"old\"}]}");cJSON*p=cJSON_Parse("[{\"op\":\"replace\",\"path\":\"/items/0/name\",\"value\":\"new\"}]");if(!d||!p)return 1;if(cJSONUtils_ApplyPatches(d,p))return 2;cJSON*v=cJSONUtils_GetPointer(d,"/items/0/name");char*out=cJSON_PrintUnformatted(d);puts(out);int ok=cJSON_IsString(v)&&!strcmp(v->valuestring,"new");cJSON_free(out);cJSON_Delete(p);cJSON_Delete(d);return ok?0:3;}
C
if pkg-config --exists libcjson_utils; then gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libcjson_utils); else gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcjson_utils -lcjson; fi
"$tmpdir/t"
