#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <sodium.h>
#include <stdio.h>
#include <string.h>
int main(void){sodium_init();unsigned char a[crypto_kx_SEEDBYTES]={1},b[crypto_kx_SEEDBYTES]={2},cp[crypto_kx_PUBLICKEYBYTES],cs[crypto_kx_SECRETKEYBYTES],sp[crypto_kx_PUBLICKEYBYTES],ss[crypto_kx_SECRETKEYBYTES],cr[crypto_kx_SESSIONKEYBYTES],ct[crypto_kx_SESSIONKEYBYTES],sr[crypto_kx_SESSIONKEYBYTES],st[crypto_kx_SESSIONKEYBYTES];crypto_kx_seed_keypair(cp,cs,a);crypto_kx_seed_keypair(sp,ss,b);if(crypto_kx_client_session_keys(cr,ct,cp,cs,sp))return 1;if(crypto_kx_server_session_keys(sr,st,sp,ss,cp))return 2;printf("session=%02x%02x\n",cr[0],ct[0]);return memcmp(cr,st,sizeof cr)||memcmp(ct,sr,sizeof ct);}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lsodium; "$tmpdir/t"
