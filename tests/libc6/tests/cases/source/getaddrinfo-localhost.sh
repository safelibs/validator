#!/usr/bin/env bash
# @testcase: getaddrinfo-localhost
# @title: glibc getaddrinfo localhost
# @description: Resolves localhost through getaddrinfo and frees the address list.
# @timeout: 120
# @tags: api, resolver

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="getaddrinfo-localhost"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  shift || true
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" "$@"
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

compile_and_run 'resolved=localhost' <<'C'
#include <netdb.h>
#include <stdio.h>
int main(void) {
    struct addrinfo hints = {0};
    struct addrinfo *result = NULL;
    hints.ai_socktype = SOCK_STREAM;
    int rc = getaddrinfo("localhost", "80", &hints, &result);
    if (rc != 0) return 1;
    freeaddrinfo(result);
    puts("resolved=localhost");
    return 0;
}
C
