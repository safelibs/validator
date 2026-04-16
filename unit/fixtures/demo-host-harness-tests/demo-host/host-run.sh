#!/usr/bin/env bash
set -euo pipefail

test "$VALIDATOR_LIBRARY" = "demo-host"
test "$PWD" = "$VALIDATOR_HARNESS_ROOT"
test -d "$VALIDATOR_HARNESS_ROOT/.git"
test -d "$VALIDATOR_HARNESS_ROOT/.validator"
test -f "$VALIDATOR_HARNESS_ROOT/dependents.json"
test -f "$VALIDATOR_HARNESS_ROOT/relevant_cves.json"
test -f "$VALIDATOR_HARNESS_ROOT/test-original.sh"
test -f "$VALIDATOR_HARNESS_ROOT/original/marker.txt"
test -f "$VALIDATOR_HARNESS_ROOT/safe/marker.txt"
test -f "$VALIDATOR_HARNESS_ROOT/build-check-install/marker.txt"
test -f "$VALIDATOR_HARNESS_ROOT/safe/debian/control"

git ls-files --error-unmatch build-check-install/marker.txt >/dev/null
git ls-files --error-unmatch original/marker.txt >/dev/null
git ls-files --error-unmatch safe/marker.txt >/dev/null
git ls-files --error-unmatch test-original.sh >/dev/null

mkdir -p "$VALIDATOR_DOWNSTREAM_DIR/raw"
raw_console="$VALIDATOR_DOWNSTREAM_DIR/raw/console.log"
raw_results="$VALIDATOR_DOWNSTREAM_DIR/raw/results.json"

printf 'pwd=%s\n' "$PWD" >>"$raw_console"
printf 'mode=%s\n' "$VALIDATOR_MODE" >>"$raw_console"

printf 'scratch-mutated:%s\n' "$VALIDATOR_MODE" >>"$VALIDATOR_HARNESS_ROOT/build-check-install/marker.txt"

if [[ "$VALIDATOR_MODE" == "original" ]]; then
  test -n "${VALIDATOR_BASELINE_IMAGE:-}"
  if [[ -n "${VALIDATOR_SAFE_DEB_DIR:-}" ]]; then
    echo "safe deb dir should be unset in original mode" >&2
    exit 1
  fi
  printf 'baseline_image=%s\n' "$VALIDATOR_BASELINE_IMAGE" >>"$raw_console"
  python3 - "$VALIDATOR_DOWNSTREAM_DIR/summary.json" "$raw_results" "$raw_console" <<'PY'
import json
import sys
from pathlib import Path

summary_path = Path(sys.argv[1])
results_path = Path(sys.argv[2])
console_path = Path(sys.argv[3])

results = {
    "selected": ["baseline-image", "scratch-git-index"],
    "passed": ["baseline-image", "scratch-git-index"],
}
results_path.write_text(json.dumps(results, indent=2) + "\n")

summary = {
    "summary_version": 1,
    "library": "demo-host",
    "mode": "original",
    "status": "passed",
    "report_format": "validator-wrapper-baseline",
    "expected_dependents": 2,
    "selected_dependents": ["baseline-image", "scratch-git-index"],
    "passed_dependents": ["baseline-image", "scratch-git-index"],
    "failed_dependents": [],
    "warned_dependents": [],
    "skipped_dependents": [],
    "artifacts": {
        "raw_results": str(results_path),
        "logs_dir": str(console_path.parent),
    },
    "notes": "Demo host baseline fixture uses an explicit workload list.",
}
summary_path.write_text(json.dumps(summary, indent=2) + "\n")
PY
else
  test -n "${VALIDATOR_SAFE_DEB_DIR:-}"
  if [[ -n "${VALIDATOR_BASELINE_IMAGE:-}" ]]; then
    echo "baseline image should be unset in safe mode" >&2
    exit 1
  fi
  safe_deb=$(find "$VALIDATOR_SAFE_DEB_DIR" -maxdepth 1 -type f -name '*.deb' | sort | head -n 1)
  test -n "$safe_deb"
  printf 'safe_deb=%s\n' "$safe_deb" >>"$raw_console"
  python3 - "$VALIDATOR_DOWNSTREAM_DIR/summary.json" "$raw_results" "$raw_console" "$safe_deb" <<'PY'
import json
import sys
from pathlib import Path

summary_path = Path(sys.argv[1])
results_path = Path(sys.argv[2])
console_path = Path(sys.argv[3])
safe_deb = Path(sys.argv[4])

results = {
    "ordered_workloads": ["safe-deb-fixture"],
    "markers": [{"workload": "safe-deb-fixture", "marker": safe_deb.name, "status": "passed"}],
}
results_path.write_text(json.dumps(results, indent=2) + "\n")

summary = {
    "summary_version": 1,
    "library": "demo-host",
    "mode": "safe",
    "status": "passed",
    "report_format": "imported-log-marker",
    "expected_dependents": 1,
    "selected_dependents": ["safe-deb-fixture"],
    "passed_dependents": ["safe-deb-fixture"],
    "failed_dependents": [],
    "warned_dependents": [],
    "skipped_dependents": [],
    "artifacts": {
        "raw_results": str(results_path),
        "logs_dir": str(console_path.parent),
    },
    "notes": "Demo host safe fixture validates the staged safe/dist directory.",
}
summary_path.write_text(json.dumps(summary, indent=2) + "\n")
PY
fi
