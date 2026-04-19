#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <csv.h>
#include <stdio.h>
#include <string.h>
int main(void){const char in[]="a,\"bad";struct csv_parser p;csv_init(&p,CSV_STRICT|CSV_STRICT_FINI);csv_parse(&p,in,strlen(in),NULL,NULL,NULL);if(csv_fini(&p,NULL,NULL,NULL)==0)return 1;printf("error=%s\n",csv_strerror(csv_error(&p)));csv_free(&p);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lcsv; "$tmpdir/t"
