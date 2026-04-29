#!/usr/bin/env bash
# @testcase: variant-tuple-roundtrip
# @title: GLib variant tuple round trip
# @description: Creates a GVariant tuple and reads the typed fields back.
# @timeout: 120
# @tags: api, variant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="variant-tuple-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  shift
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs "$@")
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

compile_and_run 'name=alpha count=7' glib-2.0 <<'C'
#include <glib.h>
#include <stdio.h>
int main(void) {
    GVariant *value = g_variant_new("(si)", "alpha", 7);
    const gchar *name = NULL;
    gint count = 0;
    g_variant_get(value, "(&si)", &name, &count);
    printf("name=%s count=%d\n", name, count);
    return count == 7 ? 0 : 1;
}
C
