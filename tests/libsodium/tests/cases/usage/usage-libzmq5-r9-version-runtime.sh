#!/usr/bin/env bash
# @testcase: usage-libzmq5-r9-version-runtime
# @title: ZeroMQ runtime version reports valid integers
# @description: Calls zmq_version() and verifies that the reported major version is at least 4 and the patch is non-negative on the libsodium-linked runtime.
# @timeout: 180
# @tags: usage, zmq
# @client: libzmq5

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/v.c" <<'C'
#include <zmq.h>
#include <stdio.h>

int main(void) {
    int major = -1, minor = -1, patch = -1;
    zmq_version(&major, &minor, &patch);
    printf("%d.%d.%d\n", major, minor, patch);
    if (major < 4) return 1;
    if (minor < 0 || patch < 0) return 2;
    return 0;
}
C

gcc "$tmpdir/v.c" -o "$tmpdir/v" $(pkg-config --cflags --libs libzmq)
"$tmpdir/v" >"$tmpdir/out.txt"
grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' "$tmpdir/out.txt"
