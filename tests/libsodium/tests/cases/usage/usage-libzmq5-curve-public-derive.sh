#!/usr/bin/env bash
# @testcase: usage-libzmq5-curve-public-derive
# @title: ZeroMQ zmq_curve_public derives matching public key
# @description: Generates a CURVE keypair via zmq_curve_keypair, then uses zmq_curve_public to derive the public key from the secret key alone, and asserts the derived 40-character Z85 public key matches the one produced by the keypair generator. Exercises libzmq5's libsodium-backed curve25519 scalar-mult-base path.
# @timeout: 180
# @tags: usage, crypto, zmq
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
  char pub[41];
  char sec[41];
  char derived[41];
  if (zmq_curve_keypair(pub, sec) != 0) return 1;
  if (strlen(pub) != 40 || strlen(sec) != 40) return 2;
  if (zmq_curve_public(derived, sec) != 0) return 3;
  if (strlen(derived) != 40) return 4;
  if (strcmp(derived, pub) != 0) {
    fprintf(stderr, "derived pub %s != original %s\n", derived, pub);
    return 5;
  }
  printf("derive-ok %zu\n", strlen(derived));
  return 0;
}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
