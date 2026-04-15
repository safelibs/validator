#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing dqlite"
  cat >/tmp/dqlite_smoke.c <<'C'
#include <dqlite.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static void fail(dqlite_node *node, const char *msg) {
  if (node != NULL) {
    const char *err = dqlite_node_errmsg(node);
    fprintf(stderr, "%s: %s\n", msg, err ? err : "<no errmsg>");
  } else {
    fprintf(stderr, "%s\n", msg);
  }
  exit(1);
}

int main(void) {
  char template[] = "/tmp/dqlite-smoke-XXXXXX";
  char *dir = mkdtemp(template);
  dqlite_node *node = NULL;

  if (dir == NULL) fail(NULL, "mkdtemp failed");
  if (dqlite_node_create(1, "1", dir, &node) != 0) fail(node, "dqlite_node_create failed");
  if (dqlite_node_set_bind_address(node, "@123") != 0) fail(node, "dqlite_node_set_bind_address failed");
  if (dqlite_node_start(node) != 0) fail(node, "dqlite_node_start failed");
  if (dqlite_node_stop(node) != 0) fail(node, "dqlite_node_stop failed");
  dqlite_node_destroy(node);
  return 0;
}
C
  cc -o /tmp/dqlite_smoke /tmp/dqlite_smoke.c $(pkg-config --cflags --libs dqlite)
  /tmp/dqlite_smoke
}

main "$@"
