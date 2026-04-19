#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
python_bin=${PYTHON:-python3}

has_config=0
has_tests_root=0
has_artifact_root=0
for arg in "$@"; do
  case "$arg" in
    --config|--config=*)
      has_config=1
      ;;
    --tests-root|--tests-root=*)
      has_tests_root=1
      ;;
    --artifact-root|--artifact-root=*)
      has_artifact_root=1
      ;;
  esac
done

default_args=()
if [[ $has_config -eq 0 ]]; then
  default_args+=(--config "$repo_root/repositories.yml")
fi
if [[ $has_tests_root -eq 0 ]]; then
  default_args+=(--tests-root "$repo_root/tests")
fi
if [[ $has_artifact_root -eq 0 ]]; then
  default_args+=(--artifact-root "${VALIDATOR_ARTIFACT_ROOT:-/tmp/validator-test-artifacts}")
fi

exec "$python_bin" "$repo_root/tools/run_matrix.py" "${default_args[@]}" "$@"
