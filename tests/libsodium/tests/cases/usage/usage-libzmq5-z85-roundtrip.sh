#!/usr/bin/env bash
# @testcase: usage-libzmq5-z85-roundtrip
# @title: libzmq5 Z85 round trip
# @description: Exercises libzmq5 z85 round trip through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: libzmq5

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-libzmq5-z85-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>
#include <string.h>
int main(void) {
  unsigned char raw[32];
  unsigned char decoded[32];
  char encoded[41];
  memset(raw, 7, sizeof(raw));
  if (!zmq_z85_encode(encoded, raw, sizeof(raw))) return 1;
  if (!zmq_z85_decode(decoded, encoded)) return 2;
  return memcmp(raw, decoded, sizeof(raw)) == 0 ? 0 : 3;
}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
