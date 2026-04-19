#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <sodium.h>
#include <stdio.h>
int main(void){if(sodium_init()<0)return 1;printf("sodium=%s\n",sodium_version_string());return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lsodium; "$tmpdir/t"
