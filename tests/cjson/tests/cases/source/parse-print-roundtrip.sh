#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

validator_require_file "$VALIDATOR_SOURCE_ROOT/tests/inputs/test1"
cat >"$tmpdir/t.c" <<'C'
#include <cjson/cJSON.h>
#include <stdio.h>
#include <stdlib.h>
int main(int argc,char**argv){FILE*f=fopen(argv[1],"rb");if(!f)return 1;fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);char*b=calloc(n+1,1);fread(b,1,n,f);fclose(f);cJSON*j=cJSON_Parse(b);if(!j)return 2;char*p=cJSON_PrintUnformatted(j);if(!p)return 3;puts(p);cJSON*a=cJSON_Parse(p);if(!a)return 4;cJSON_Delete(a);cJSON_free(p);cJSON_Delete(j);free(b);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcjson
"$tmpdir/t" "$VALIDATOR_SOURCE_ROOT/tests/inputs/test1" | tee "$tmpdir/out.json"
python3 -m json.tool "$tmpdir/out.json" >/dev/null
