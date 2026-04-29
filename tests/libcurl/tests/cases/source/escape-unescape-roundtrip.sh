#!/usr/bin/env bash
# @testcase: escape-unescape-roundtrip
# @title: libcurl URL escape round trip
# @description: Escapes and unescapes a string with public libcurl URL helpers.
# @timeout: 120
# @tags: api, url

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="escape-unescape-roundtrip"
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

compile_and_run 'decoded=value with spaces' <<'C'
#include <curl/curl.h>
#include <stdio.h>
#include <string.h>
int main(void) {
    CURL *curl = curl_easy_init();
    if (!curl) return 1;
    char *encoded = curl_easy_escape(curl, "value with spaces", 17);
    int outlen = 0;
    char *decoded = curl_easy_unescape(curl, encoded, 0, &outlen);
    printf("encoded=%s decoded=%.*s\n", encoded, outlen, decoded);
    int ok = decoded && strncmp(decoded, "value with spaces", outlen) == 0;
    curl_free(encoded);
    curl_free(decoded);
    curl_easy_cleanup(curl);
    return ok ? 0 : 2;
}
C
