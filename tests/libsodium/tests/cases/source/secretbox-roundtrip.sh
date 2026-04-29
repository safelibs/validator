#!/usr/bin/env bash
# @testcase: secretbox-roundtrip
# @title: libsodium secretbox round trip
# @description: Encrypts and decrypts a message with crypto_secretbox_easy public APIs.
# @timeout: 120
# @tags: api, crypto

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <sodium.h>
#include <stdio.h>
#include <string.h>
int main(void){if(sodium_init()<0)return 1;unsigned char k[crypto_secretbox_KEYBYTES]={0},n[crypto_secretbox_NONCEBYTES]={0};const unsigned char m[]="secretbox payload";unsigned char c[sizeof m+crypto_secretbox_MACBYTES],o[sizeof m];crypto_secretbox_easy(c,m,sizeof m,n,k);if(crypto_secretbox_open_easy(o,c,sizeof c,n,k))return 2;printf("message=%s\n",o);return strcmp((char*)o,(char*)m);}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lsodium; "$tmpdir/t"
