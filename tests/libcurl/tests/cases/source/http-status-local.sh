#!/usr/bin/env bash
# @testcase: http-status-local
# @title: libcurl local HTTP status
# @description: Requests a local HTTP fixture and verifies the returned response code.
# @timeout: 120
# @tags: api, http

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="http-status-local"
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

port=18080
start_http_server "$port"
compile_and_run 'status=200' "http://127.0.0.1:$port/plain.txt" <<'C'
#include <curl/curl.h>
#include <stdio.h>
static size_t discard(char *ptr, size_t size, size_t nmemb, void *userdata) {
    (void)ptr; (void)userdata; return size * nmemb;
}
int main(int argc, char **argv) {
    CURL *curl = curl_easy_init();
    long status = 0;
    if (!curl || argc != 2) return 1;
    curl_easy_setopt(curl, CURLOPT_URL, argv[1]);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, discard);
    CURLcode rc = curl_easy_perform(curl);
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &status);
    curl_easy_cleanup(curl);
    printf("status=%ld\n", status);
    return rc == CURLE_OK && status == 200 ? 0 : 2;
}
C
