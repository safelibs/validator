#!/usr/bin/env bash
# @testcase: usage-exif-cli-remove-missing-copyright
# @title: exif --remove --tag=Copyright handles tag absent from fixture
# @description: Confirms the canon fixture has no Copyright tag in IFD 0, then runs exif --remove --tag=Copyright --ifd=0 against a copy and checks that the client either errors out cleanly or no-ops without corrupting the file, with IFD 0 still loading 9 entries afterwards.
# @timeout: 120
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-remove-missing-copyright"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

# Baseline: Copyright must be absent from the canon fixture
set +e
exif --tag=Copyright --ifd=0 "$img" >"$tmpdir/baseline.stdout" 2>"$tmpdir/baseline.stderr"
baseline_rc=$?
set -e
cat "$tmpdir/baseline.stdout" "$tmpdir/baseline.stderr" >"$tmpdir/baseline.all"
if (( baseline_rc == 0 )) && ! grep -qE "does not contain a? ?tag 'Copyright'" "$tmpdir/baseline.all"; then
  printf 'unexpected baseline state: Copyright already present in fixture\n' >&2
  cat "$tmpdir/baseline.all" >&2
  exit 1
fi

# Attempt to remove the absent Copyright tag from a copy
cp "$img" "$tmpdir/source.jpg"
set +e
exif --remove --tag=Copyright --ifd=0 \
  --output="$tmpdir/stripped.jpg" "$tmpdir/source.jpg" \
  >"$tmpdir/remove.stdout" 2>"$tmpdir/remove.stderr"
remove_rc=$?
set -e
cat "$tmpdir/remove.stdout" "$tmpdir/remove.stderr" >"$tmpdir/remove.all"

if (( remove_rc == 0 )); then
  # No-op path: any output file produced must keep the original 9-entry IFD 0
  if [[ -e "$tmpdir/stripped.jpg" ]]; then
    exif --debug "$tmpdir/stripped.jpg" >"$tmpdir/after.log" 2>&1
    validator_assert_contains "$tmpdir/after.log" 'ExifData: Loading 9 entries...'
  fi
else
  # Error path: client must explain that the requested tag is not present
  grep -qE "does not contain a? ?tag 'Copyright'" "$tmpdir/remove.all" || {
    printf "expected diagnostic about missing Copyright tag, got:\n" >&2
    cat "$tmpdir/remove.all" >&2
    exit 1
  }
fi

# In every case the original fixture must remain unmodified and still load 9 entries
exif --debug "$img" >"$tmpdir/original.log" 2>&1
validator_assert_contains "$tmpdir/original.log" 'ExifData: Loading 9 entries...'
