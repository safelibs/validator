#!/usr/bin/env bash
# @testcase: usage-gawk-r14-procinfo-version-key
# @title: gawk PROCINFO["version"] reports a non-empty version string
# @description: Reads PROCINFO["version"] in a BEGIN block under LC_ALL=C, asserts the string is non-empty and starts with a digit (gawk version banner), and asserts PROCINFO["pid"] is a positive integer matching the gawk process id from the shell.
# @timeout: 60
# @tags: usage, gawk, procinfo
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C gawk 'BEGIN {
  ver = PROCINFO["version"]
  if (length(ver) == 0) { print "empty version" > "/dev/stderr"; exit 1 }
  if (ver !~ /^[0-9]/) { printf "version not digit-led: %s\n", ver > "/dev/stderr"; exit 1 }
  pid = PROCINFO["pid"]
  if (pid !~ /^[0-9]+$/) { printf "bad pid: %s\n", pid > "/dev/stderr"; exit 1 }
  if (pid + 0 <= 0) { print "non-positive pid" > "/dev/stderr"; exit 1 }
  print "ok", ver, pid
}' >"$tmpdir/out.txt"

# Output line should begin with "ok " and have three whitespace-separated fields.
LC_ALL=C grep -E '^ok [0-9][^ ]* [0-9]+$' "$tmpdir/out.txt" >/dev/null
