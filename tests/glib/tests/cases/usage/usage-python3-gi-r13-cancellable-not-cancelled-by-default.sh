#!/usr/bin/env bash
# @testcase: usage-python3-gi-r13-cancellable-not-cancelled-by-default
# @title: PyGObject Gio.Cancellable starts uncancelled and reports cancelled after cancel
# @description: Constructs a fresh Gio.Cancellable, asserts is_cancelled returns False, then invokes cancel() and asserts is_cancelled returns True on the same instance.
# @timeout: 60
# @tags: usage, python, gio, cancellable
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import Gio

c = Gio.Cancellable.new()
print("before=" + str(c.is_cancelled()))
c.cancel()
print("after=" + str(c.is_cancelled()))
PY

validator_assert_contains "$tmpdir/out" 'before=False'
validator_assert_contains "$tmpdir/out" 'after=True'
