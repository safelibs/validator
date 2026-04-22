#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  version-info-smoke)
    compile_and_run 'version=' <<'C'
#include <curl/curl.h>
#include <stdio.h>
int main(void) {
    curl_version_info_data *info = curl_version_info(CURLVERSION_NOW);
    printf("version=%s ssl=%s\n", info->version, info->ssl_version ? info->ssl_version : "none");
    return info->version ? 0 : 1;
}
C
    ;;
  easy-file-read)
    printf 'file payload through libcurl\n' >"$tmpdir/payload.txt"
    compile_and_run 'file payload' "file://$tmpdir/payload.txt" <<'C'
#include <curl/curl.h>
#include <stdio.h>
static size_t write_cb(char *ptr, size_t size, size_t nmemb, void *userdata) {
    return fwrite(ptr, size, nmemb, (FILE *)userdata);
}
int main(int argc, char **argv) {
    CURL *curl = curl_easy_init();
    if (!curl || argc != 2) return 1;
    curl_easy_setopt(curl, CURLOPT_URL, argv[1]);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, stdout);
    CURLcode rc = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
    return rc == CURLE_OK ? 0 : 2;
}
C
    ;;
  escape-unescape-roundtrip)
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
    ;;
  slist-header-build)
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
    ;;
  http-status-local)
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
    ;;
  *)
    printf 'unknown libcurl source case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
