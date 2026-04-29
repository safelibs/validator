#!/usr/bin/env bash
# @testcase: version-info-smoke
# @title: libcurl version info
# @description: Reads libcurl version and SSL backend metadata through curl_version_info.
# @timeout: 120
# @tags: api, version

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="version-info-smoke"
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

compile_and_run 'version=' <<'C'
#include <curl/curl.h>
#include <stdio.h>
int main(void) {
    curl_version_info_data *info = curl_version_info(CURLVERSION_NOW);
    printf("version=%s ssl=%s\n", info->version, info->ssl_version ? info->ssl_version : "none");
    return info->version ? 0 : 1;
}
C
