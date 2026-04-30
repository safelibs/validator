#!/usr/bin/env bash
# @testcase: usage-python3-gi-iochannel-read-line
# @title: PyGObject GLib IOChannel read_line
# @description: Opens a local text file with GLib.IOChannel.new_file from PyGObject and reads it line by line, verifying line count and content of the first and last line.
# @timeout: 180
# @tags: usage, glib, python, iochannel
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-iochannel-read-line"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/input.txt" <<'TXT'
alpha
beta
gamma
TXT

INPUT_PATH="$tmpdir/input.txt" python3 >"$tmpdir/out" <<'PY'
import os
from gi.repository import GLib

path = os.environ["INPUT_PATH"]
ch = GLib.IOChannel.new_file(path, "r")
lines = []
while True:
    status, line, length, terminator = ch.read_line()
    if status != GLib.IOStatus.NORMAL:
        break
    lines.append(line.rstrip("\n"))
ch.shutdown(False)

print("count=" + str(len(lines)))
print("first=" + lines[0])
print("last=" + lines[-1])
PY

validator_assert_contains "$tmpdir/out" 'count=3'
validator_assert_contains "$tmpdir/out" 'first=alpha'
validator_assert_contains "$tmpdir/out" 'last=gamma'
