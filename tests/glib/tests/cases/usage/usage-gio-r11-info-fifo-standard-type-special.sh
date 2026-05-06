#!/usr/bin/env bash
# @testcase: usage-gio-r11-info-fifo-standard-type-special
# @title: gio info classifies a named pipe as standard::type 4 (special)
# @description: Creates a FIFO with mkfifo and verifies that "gio info -a standard::type" reports the GIO file-type code 4 (special) under the attributes block, and the human "type:" line reads "special".
# @timeout: 60
# @tags: usage, gio, info, fifo
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkfifo "$tmpdir/myfifo"
gio info -a standard::type "$tmpdir/myfifo" >"$tmpdir/out"
attr=$(awk -F': ' '/^  standard::type:/ {print $2; exit}' "$tmpdir/out")
[[ "$attr" == "4" ]] || { printf 'expected attr=4 got=%s\n' "$attr" >&2; sed -n '1,40p' "$tmpdir/out" >&2; exit 1; }
grep -E '^type:[[:space:]]+special$' "$tmpdir/out" >/dev/null
