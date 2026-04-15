#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing libstorj"
  (
    set -euo pipefail
    local dir
    dir="$(mktemp -d /tmp/storj-test.XXXXXX)"
    cat >"${dir}/server.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            body = b'{"info":"ok"}'
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_error(404)

    def log_message(self, fmt, *args):
        pass

HTTPServer(("127.0.0.1", 8091), Handler).serve_forever()
PY
    python3 "${dir}/server.py" >"${dir}/server.log" 2>&1 &
    spid=$!
    trap 'kill "${spid}" 2>/dev/null || true; wait "${spid}" 2>/dev/null || true' EXIT
    for _ in $(seq 1 50); do
      if curl -fsS http://127.0.0.1:8091/ >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
    done
    cat >/tmp/storj_smoke.c <<'C'
#include <storj.h>
#include <stdio.h>
#include <stdlib.h>

static uv_loop_t *g_loop = NULL;
static int g_status = 1;

static void after_info(uv_work_t *work, int status) {
  json_request_t *req = work->data;
  if (status == 0 && req != NULL && req->response != NULL) {
    struct json_object *value = NULL;
    if (json_object_object_get_ex(req->response, "info", &value)) {
      g_status = 0;
    }
  }
  if (req != NULL && req->response != NULL) {
    json_object_put(req->response);
  }
  free(req);
  free(work);
  if (g_loop != NULL) {
    uv_stop(g_loop);
  }
}

int main(void) {
  storj_bridge_options_t options = {
    .proto = "http",
    .host = "127.0.0.1",
    .port = 8091,
    .user = NULL,
    .pass = NULL,
  };
  storj_http_options_t http_options = {
    .user_agent = "storj-smoke",
    .proxy_url = NULL,
    .low_speed_limit = 0,
    .low_speed_time = 0,
    .timeout = 5,
  };
  storj_log_options_t log_options = {
    .logger = NULL,
    .level = 0,
  };
  storj_env_t *env = storj_init_env(&options, NULL, &http_options, &log_options);
  if (env == NULL) {
    fprintf(stderr, "storj_init_env failed\n");
    return 1;
  }
  g_loop = env->loop;
  if (storj_bridge_get_info(env, NULL, after_info) != 0) {
    fprintf(stderr, "storj_bridge_get_info failed\n");
    storj_destroy_env(env);
    return 1;
  }
  uv_run(env->loop, UV_RUN_DEFAULT);
  if (storj_destroy_env(env) != 0) {
    fprintf(stderr, "storj_destroy_env failed\n");
    return 1;
  }
  return g_status;
}
C
    cc -o /tmp/storj_smoke /tmp/storj_smoke.c $(pkg-config --cflags --libs libstorj)
    /tmp/storj_smoke
  )
}

main "$@"
