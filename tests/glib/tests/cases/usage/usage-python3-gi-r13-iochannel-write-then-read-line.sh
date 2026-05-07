#!/usr/bin/env bash
# @testcase: usage-python3-gi-r13-iochannel-write-then-read-line
# @title: PyGObject GLib.IOChannel writes a multi-line payload and reads it back line by line
# @description: Opens an IOChannel for writing, emits three text lines, flushes, reopens the file for reading, and asserts read_line yields the same three lines in order before reaching EOF.
# @timeout: 60
# @tags: usage, python, iochannel
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

INPUT_PATH="$tmpdir/io.txt" python3 >"$tmpdir/out" <<'PY'
import os
from gi.repository import GLib

path = os.environ["INPUT_PATH"]

writer = GLib.IOChannel.new_file(path, "w")
for line in ("alpha\n", "beta\n", "gamma\n"):
    writer.write(line)
writer.shutdown(True)

reader = GLib.IOChannel.new_file(path, "r")
lines = []
while True:
    status, line, length, terminator = reader.read_line()
    if status != GLib.IOStatus.NORMAL:
        break
    lines.append(line.rstrip("\n"))
reader.shutdown(False)

print("count=" + str(len(lines)))
print("first=" + lines[0])
print("middle=" + lines[1])
print("last=" + lines[-1])
PY

validator_assert_contains "$tmpdir/out" 'count=3'
validator_assert_contains "$tmpdir/out" 'first=alpha'
validator_assert_contains "$tmpdir/out" 'middle=beta'
validator_assert_contains "$tmpdir/out" 'last=gamma'
