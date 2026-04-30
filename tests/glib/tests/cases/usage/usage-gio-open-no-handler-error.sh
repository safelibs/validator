#!/usr/bin/env bash
# @testcase: usage-gio-open-no-handler-error
# @title: gio open reports error for unhandled type
# @description: Invokes gio open against a file with a fabricated extension and verifies the command reports an error (non-zero exit and a diagnostic on stderr) rather than silently succeeding.
# @timeout: 120
# @tags: usage, gio, open
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-open-no-handler-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Run gio open in an environment where no GUI/desktop handlers exist:
# scrub DISPLAY/WAYLAND_DISPLAY so portal-backed handlers cannot match
# and point XDG_DATA_DIRS at an empty directory so no .desktop files
# advertise a handler for our fabricated MIME type.
mkdir -p "$tmpdir/empty-xdg"
mkdir -p "$tmpdir/home"
target="$tmpdir/payload.safelibs-validator-no-handler"
printf 'no-handler payload\n' >"$target"

set +e
env -u DISPLAY -u WAYLAND_DISPLAY \
    XDG_DATA_DIRS="$tmpdir/empty-xdg" \
    XDG_DATA_HOME="$tmpdir/home" \
    HOME="$tmpdir/home" \
  gio open "$target" >"$tmpdir/out" 2>"$tmpdir/err"
status=$?
set -e

if (( status == 0 )); then
  printf 'expected gio open to fail without a handler, got exit 0\n' >&2
  printf '--- stdout ---\n' >&2
  sed -n '1,40p' "$tmpdir/out" >&2
  printf '--- stderr ---\n' >&2
  sed -n '1,40p' "$tmpdir/err" >&2
  exit 1
fi

# Diagnostic should mention either the failing path or the missing
# application/handler. Keep the assertion lenient across glib versions.
combined="$tmpdir/combined"
cat "$tmpdir/out" "$tmpdir/err" >"$combined"
if ! grep -Eqi 'no application|no.*handler|failed|error|registered' "$combined"; then
  printf 'expected gio open to print an error diagnostic, got:\n' >&2
  sed -n '1,40p' "$combined" >&2
  exit 1
fi
