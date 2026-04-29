#!/usr/bin/env bash
# @testcase: pthread-thread-join
# @title: glibc pthread join
# @description: Starts a POSIX thread and joins it through libc pthread entry points.
# @timeout: 120
# @tags: api, pthread

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="pthread-thread-join"
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

compile_and_run 'thread=42' -pthread <<'C'
#include <pthread.h>
#include <stdio.h>
static void *worker(void *arg) {
    int *value = arg;
    *value = 42;
    return NULL;
}
int main(void) {
    pthread_t thread;
    int value = 0;
    if (pthread_create(&thread, NULL, worker, &value)) return 1;
    if (pthread_join(thread, NULL)) return 2;
    printf("thread=%d\n", value);
    return value == 42 ? 0 : 3;
}
C
