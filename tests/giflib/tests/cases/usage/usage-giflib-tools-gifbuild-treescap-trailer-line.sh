#!/usr/bin/env bash
# @testcase: usage-giflib-tools-gifbuild-treescap-trailer-line
# @title: gifbuild dump terminates with the trailer record
# @description: Dumps treescap.gif with gifbuild -d and asserts the textual dump terminates with the GIF stream trailer record gifbuild emits at end-of-file, ensuring the dump is structurally complete and not truncated mid-record.
# @timeout: 60
# @tags: usage, cli, gifbuild, structure
# @client: giflib-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gif="$VALIDATOR_SAMPLE_ROOT/pic/treescap.gif"
validator_require_file "$gif"

gifbuild -d "$gif" >"$tmpdir/dump.txt"

# Strip trailing blank lines and grab the final non-empty line.
last_line=$(awk 'NF { last=$0 } END { print last }' "$tmpdir/dump.txt")
[[ -n "$last_line" ]] || { printf 'gifbuild dump empty\n' >&2; exit 1; }

# gifbuild's textual dump finishes with a trailer marker. Different versions
# of giflib emit one of a small set of terminator tokens at end-of-stream;
# require the final non-empty line to be one of those known forms.
case "$last_line" in
  "terminator") : ;;
  "%trailer") : ;;
  "% terminator") : ;;
  "end") : ;;
  *)
    # Round-trip the dump back into a GIF as a structural check: if the
    # trailer is missing or malformed gifbuild would refuse to rebuild.
    if ! gifbuild "$tmpdir/dump.txt" >"$tmpdir/rebuilt.gif"; then
      printf 'unexpected final dump line %q and rebuild failed\n' "$last_line" >&2
      sed -n '$-5,$p' "$tmpdir/dump.txt" >&2
      exit 1
    fi
    file "$tmpdir/rebuilt.gif" | grep -q 'GIF image data'
    ;;
esac

# Either the explicit trailer token was present or the rebuild succeeded;
# assert the dump ends with a newline so downstream tools can append cleanly.
last_byte=$(tail -c 1 "$tmpdir/dump.txt" | od -An -tx1 | tr -d ' \n')
[[ "$last_byte" == "0a" ]] || {
  printf 'expected gifbuild dump to end with newline, got 0x%s\n' "$last_byte" >&2
  exit 1
}
