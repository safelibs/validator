#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    cat >"$tmpdir/t.c" <<'C'
#include <cjson/cJSON.h>
#include <stdio.h>
int main(void) { cJSON *r=cJSON_Parse("{\"view\":{\"width\":1920,\"height\":1080}}"); if(!r) return 1; cJSON *v=cJSON_GetObjectItemCaseSensitive(r,"view"); if(!v) return 2; char *s=cJSON_PrintUnformatted(r); puts(s); cJSON_free(s); cJSON_Delete(r); return 0; }
C
    gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcjson
    "$tmpdir/t"
