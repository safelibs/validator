#!/usr/bin/env bash
# @testcase: usage-libzmq5-r21-curve-public-from-z85-secret-roundtrip
# @title: ZeroMQ zmq_curve_public re-derives the Z85 public key from a generated secret key
# @description: Compiles a C program that calls zmq_curve_keypair to generate a Z85 pub/sec pair, then calls zmq_curve_public on the secret to re-derive the public, and asserts both Z85 buffers are length 40 and byte-identical, exercising libsodium-backed curve25519 scalar multiplication through libzmq.
# @timeout: 180
# @tags: usage, zmq, curve, public-derive, r21
# @client: libzmq5

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    char pub[41]={0}, sec[41]={0}, derived[41]={0};
    if (zmq_curve_keypair(pub, sec) != 0) return 1;
    if (zmq_curve_public(derived, sec) != 0) return 2;
    if (strlen(pub) != 40) return 3;
    if (strlen(derived) != 40) return 4;
    if (strcmp(pub, derived) != 0) {
        fprintf(stderr, "derived mismatch pub=%s derived=%s\n", pub, derived);
        return 5;
    }
    puts("ok curve_public_match");
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'ok curve_public_match'
