#!/usr/bin/env bash
# @testcase: example-tool-compile-run
# @title: Example tool compile and run
# @description: Builds an upstream example tool and runs it against a fixture CSV.
# @timeout: 120
# @tags: api, example

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

validator_require_file "$VALIDATOR_SAMPLE_ROOT/tests/test_01.csv"
cat >"$tmpdir/csv-client.c" <<'C'
#include <csv.h>
#include <stdio.h>
#include <stdlib.h>

struct state {
    size_t fields;
};

static void field_cb(void *data, size_t len, void *ctx) {
    struct state *state = ctx;
    if (state->fields > 0) {
        putchar(',');
    }
    fwrite(data, 1, len, stdout);
    state->fields++;
}

static void row_cb(int ch, void *ctx) {
    (void)ch;
    (void)ctx;
    putchar('\n');
}

int main(void) {
    struct csv_parser parser;
    struct state state = {0};
    char buf[128];
    size_t n;

    if (csv_init(&parser, 0) != 0) {
        return 1;
    }
    while ((n = fread(buf, 1, sizeof(buf), stdin)) > 0) {
        if (csv_parse(&parser, buf, n, field_cb, row_cb, &state) != n) {
            csv_free(&parser);
            return 2;
        }
    }
    if (ferror(stdin)) {
        csv_free(&parser);
        return 3;
    }
    if (csv_fini(&parser, field_cb, row_cb, &state) != 0) {
        csv_free(&parser);
        return 4;
    }
    csv_free(&parser);
    return state.fields == 5 ? 0 : 5;
}
C
gcc "$tmpdir/csv-client.c" -o "$tmpdir/csv-client" -lcsv
"$tmpdir/csv-client" <"$VALIDATOR_SAMPLE_ROOT/tests/test_01.csv" | tee "$tmpdir/out"
grep ',' "$tmpdir/out"
