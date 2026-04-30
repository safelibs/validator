#!/usr/bin/env bash
# @testcase: usage-gio-trash-list-empty
# @title: gio mime registers and reports default handler
# @description: Registers a default mime handler with gio mime against an isolated XDG data home, then queries it back and verifies gio reports the registered desktop entry as the default.
# @timeout: 180
# @tags: usage, gio, mime
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Isolate XDG dirs so we don't perturb anything else and so the only handler
# gio can find is the one we register here.
export XDG_DATA_HOME="$tmpdir/data"
export XDG_CONFIG_HOME="$tmpdir/config"
export XDG_DATA_DIRS="$tmpdir/data:/usr/share"
mkdir -p "$XDG_DATA_HOME/applications" "$XDG_CONFIG_HOME"

cat >"$XDG_DATA_HOME/applications/validator-handler.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Validator Handler
Exec=/bin/true %f
NoDisplay=true
DESKTOP

# Refresh the mime cache so gio mime can discover the new handler.
update-desktop-database "$XDG_DATA_HOME/applications" >/dev/null 2>&1 || true

mime="application/x-validator-test"
gio mime "$mime" "validator-handler.desktop" >"$tmpdir/set.out" 2>&1 || {
  printf 'gio mime set failed:\n' >&2
  cat "$tmpdir/set.out" >&2
  exit 1
}

gio mime "$mime" >"$tmpdir/query.out" 2>&1 || {
  printf 'gio mime query failed:\n' >&2
  cat "$tmpdir/query.out" >&2
  exit 1
}

validator_assert_contains "$tmpdir/query.out" 'validator-handler.desktop'
