#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <sodium.h>
#include <stdio.h>
int main(void){sodium_init();unsigned char pk[crypto_sign_PUBLICKEYBYTES],sk[crypto_sign_SECRETKEYBYTES],sig[crypto_sign_BYTES];unsigned long long l;const unsigned char m[]="signed";crypto_sign_keypair(pk,sk);crypto_sign_detached(sig,&l,m,sizeof m,sk);printf("signature=%llu\n",l);return crypto_sign_verify_detached(sig,m,sizeof m,pk);}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lsodium; "$tmpdir/t"
