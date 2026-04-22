#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  stdio-string-conversion)
    compile_and_run 'value=42.5 text=answer' <<'C'
#include <stdio.h>
#include <stdlib.h>
int main(void) {
    char buf[64];
    double value = strtod("42.5", NULL);
    snprintf(buf, sizeof buf, "value=%.1f text=%s", value, "answer");
    puts(buf);
    return value == 42.5 ? 0 : 1;
}
C
    ;;
  pthread-thread-join)
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
    ;;
  locale-collation)
    compile_and_run 'locale=C.UTF-8' <<'C'
#include <locale.h>
#include <stdio.h>
#include <string.h>
int main(void) {
    const char *locale = setlocale(LC_ALL, "C.UTF-8");
    int cmp = strcoll("alpha", "beta");
    printf("locale=%s cmp=%d\n", locale ? locale : "missing", cmp < 0);
    return locale && cmp < 0 ? 0 : 1;
}
C
    ;;
  dlopen-libm-symbol)
    compile_and_run 'cos=1.0' -ldl <<'C'
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
int main(void) {
    void *handle = dlopen("libm.so.6", RTLD_NOW);
    if (!handle) return 1;
    double (*cos_fn)(double) = dlsym(handle, "cos");
    if (!cos_fn) return 2;
    printf("cos=%.1f\n", cos_fn(0.0));
    dlclose(handle);
    return 0;
}
C
    ;;
  getaddrinfo-localhost)
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
    ;;
  *)
    printf 'unknown libc6 source case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
