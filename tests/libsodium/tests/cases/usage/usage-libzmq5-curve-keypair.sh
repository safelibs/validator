#!/usr/bin/env bash
# @testcase: usage-libzmq5-curve-keypair
# @title: ZeroMQ CURVE keypair
# @description: Compiles a ZeroMQ client snippet that generates a CURVE keypair backed by libsodium.
# @timeout: 180
# @tags: usage, crypto, zmq
# @client: libzmq5

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libzmq5-curve-keypair"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>
#include <string.h>
int main(void) {
  char pub[41];
  char sec[41];
  if (zmq_curve_keypair(pub, sec) != 0) return 1;
  printf("curve-keypair %zu %zu\n", strlen(pub), strlen(sec));
  return (strlen(pub) == 40 && strlen(sec) == 40) ? 0 : 2;
}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
