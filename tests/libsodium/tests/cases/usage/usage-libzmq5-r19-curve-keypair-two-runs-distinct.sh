#!/usr/bin/env bash
# @testcase: usage-libzmq5-r19-curve-keypair-two-runs-distinct
# @title: ZeroMQ zmq_curve_keypair returns distinct (public, secret) Z85 keys across two calls
# @description: Compiles a C program that calls zmq_curve_keypair twice in the same process to populate two pairs of 41-byte Z85 buffers, asserts each public and secret string is exactly 40 characters, and asserts pub1!=pub2 and sec1!=sec2 byte-wise, confirming libsodium-backed randomness produces fresh CURVE material on every invocation.
# @timeout: 180
# @tags: usage, zmq, curve, keypair, r19
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
    char p1[41]={0}, s1[41]={0}, p2[41]={0}, s2[41]={0};
    if (zmq_curve_keypair(p1, s1) != 0) return 1;
    if (zmq_curve_keypair(p2, s2) != 0) return 2;
    if (strlen(p1) != 40 || strlen(p2) != 40) return 3;
    if (strlen(s1) != 40 || strlen(s2) != 40) return 4;
    if (strcmp(p1, p2) == 0) { fprintf(stderr, "pub collided\n"); return 5; }
    if (strcmp(s1, s2) == 0) { fprintf(stderr, "sec collided\n"); return 6; }
    puts("ok");
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
