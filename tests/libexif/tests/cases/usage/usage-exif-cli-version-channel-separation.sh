#!/usr/bin/env bash
# @testcase: usage-exif-cli-version-channel-separation
# @title: exif --version writes only to stdout with a clean stderr
# @description: Runs the exif client with --version while capturing stdout and stderr separately and verifies the version banner lands exclusively on stdout as a single 0.6.x release identifier with no leading "exif" prefix or trailing copyright lines, and that stderr is empty. This pins the channel separation contract so dependent clients can `read VER < <(exif --version)` without coping with stderr noise.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-version-channel-separation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

exif --version >"$tmpdir/stdout" 2>"$tmpdir/stderr"

# stderr must be empty
stderr_size=$(stat -c '%s' "$tmpdir/stderr")
if (( stderr_size != 0 )); then
  printf 'expected empty stderr from --version, got %d bytes\n' "$stderr_size" >&2
  cat "$tmpdir/stderr" >&2
  exit 1
fi

# stdout must be a single non-empty line that looks like a 0.6.x release
stdout_lines=$(wc -l <"$tmpdir/stdout")
if (( stdout_lines != 1 )); then
  printf 'expected exactly 1 stdout line from --version, got %d\n' "$stdout_lines" >&2
  cat "$tmpdir/stdout" >&2
  exit 1
fi

if ! grep -Eq '^0\.6\.[0-9]+$' "$tmpdir/stdout"; then
  printf 'unexpected --version stdout content (expected bare 0.6.x)\n' >&2
  cat "$tmpdir/stdout" >&2
  exit 1
fi

# Sanity: the banner must not be prefixed with "exif " or carry copyright text
if grep -qiE '^exif[[:space:]]|copyright|gpl|license' "$tmpdir/stdout"; then
  printf 'unexpected prose in --version banner\n' >&2
  cat "$tmpdir/stdout" >&2
  exit 1
fi
