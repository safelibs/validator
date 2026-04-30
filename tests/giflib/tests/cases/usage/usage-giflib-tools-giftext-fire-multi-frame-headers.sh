#!/usr/bin/env bash
# @testcase: usage-giflib-tools-giftext-fire-multi-frame-headers
# @title: giftext fire emits per-frame Image headers
# @description: Runs giftext on the animated fire.gif fixture and asserts more than one Image #N header is emitted with strictly increasing sequence numbers starting at 1.
# @timeout: 60
# @tags: usage, cli, giftext, animation
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/fire.gif"
validator_require_file "$gif"

giftext "$gif" >"$tmpdir/info.txt"

grep -E '^Image #[0-9]+:' "$tmpdir/info.txt" >"$tmpdir/headers.txt"
header_count=$(wc -l <"$tmpdir/headers.txt")
(( header_count > 1 )) || {
  printf 'expected multiple Image headers, got %d\n' "$header_count" >&2
  sed -n '1,40p' "$tmpdir/info.txt" >&2
  exit 1
}

# First header must be Image #1 and indices must be strictly increasing.
python3 - <<'PY' "$tmpdir/headers.txt"
import re, sys
nums = []
with open(sys.argv[1]) as fh:
    for line in fh:
        m = re.match(r'Image #(\d+):', line)
        if m:
            nums.append(int(m.group(1)))
if not nums or nums[0] != 1:
    sys.exit(f"expected Image #1 first, got {nums[:3]}")
if nums != sorted(set(nums)):
    sys.exit(f"Image header sequence not strictly increasing: {nums}")
PY
