#!/usr/bin/env bash
# @testcase: generichash-smoke
# @title: libsodium hash behavior
# @description: Computes a libsodium generic hash and prints the digest prefix.
# @timeout: 120
# @tags: api, crypto

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <sodium.h>
#include <stdio.h>
int main(void){if(sodium_init()<0)return 1;unsigned char o[crypto_generichash_BYTES];crypto_generichash(o,sizeof o,(unsigned char*)"message",7,NULL,0);printf("hash=%02x%02x%02x%02x\n",o[0],o[1],o[2],o[3]);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lsodium; "$tmpdir/t"
