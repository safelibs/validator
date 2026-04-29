#!/usr/bin/env bash
# @testcase: malformed-number-rejection
# @title: Malformed number rejection
# @description: Requires cJSON to reject incomplete exponent notation in a number token.
# @timeout: 120
# @tags: api, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <cjson/cJSON.h>
#include <stdio.h>
int main(void){const char*end=NULL;cJSON*j=cJSON_ParseWithOpts("[1e+]",&end,1);if(j){cJSON_Delete(j);return 1;}printf("parse stopped near: %s\n",end?end:"<null>");return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcjson
"$tmpdir/t"
