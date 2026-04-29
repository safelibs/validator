#!/usr/bin/env bash
# @testcase: slist-header-build
# @title: libcurl slist header build
# @description: Builds and frees a curl_slist of HTTP headers.
# @timeout: 120
# @tags: api, headers

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="slist-header-build"
tmpdir=$(mktemp -d)
trap 'jobs -pr | xargs -r kill 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  shift || true
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libcurl)
  "$tmpdir/t" "$@" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

start_http_server() {
  local port=$1
  mkdir -p "$tmpdir/www"
  printf 'downloaded through libcurl\n' >"$tmpdir/www/plain.txt"
  python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/www" >"$tmpdir/http.log" 2>&1 &
  for _ in $(seq 1 40); do
    curl -fsS "http://127.0.0.1:$port/plain.txt" >/dev/null 2>&1 && return 0
    sleep 0.25
  done
  cat "$tmpdir/http.log" >&2
  return 1
}

compile_and_run 'headers=2' <<'C'
#include <curl/curl.h>
#include <stdio.h>
int main(void) {
    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "X-Validator: one");
    headers = curl_slist_append(headers, "Accept: text/plain");
    int count = 0;
    for (struct curl_slist *it = headers; it; it = it->next) count++;
    printf("headers=%d\n", count);
    curl_slist_free_all(headers);
    return count == 2 ? 0 : 1;
}
C
