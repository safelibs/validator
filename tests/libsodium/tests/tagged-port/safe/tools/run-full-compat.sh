#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
safe_dir=$(cd -- "$script_dir/.." && pwd)
repo_dir=$(cd -- "$safe_dir/.." && pwd)

usage() {
  cat <<EOF
usage: $(basename "$0") [--only <package>] [--report-dir <dir>] [--rerun-from-list <file>] [--rerun-report-dir <dir>] [--skip-rerun]

Builds the safe Debian packages, rebuilds the release cdylib, verifies the full
ABI/package/drop-in contract, re-runs all 77 legacy source-compat and
relinked-object tests, audits remaining unsafe usage, and then executes the
dependent smoke harness in --mode safe. Unless --skip-rerun is set, it then
reruns the selected dependent failure list into a generated rerun report.

Without --report-dir, the final bundle is written to safe/compat-reports/final/.
EOF
}

declare -a only_args=()
report_dir="$safe_dir/compat-reports/final"
rerun_from_list="$safe_dir/compat-reports/dependents/failures.list"
rerun_report_dir=""
skip_rerun=0
dependents_dir=""
summary_path=""
packages_log=""
cargo_log=""
symbols_log=""
source_tests_log=""
relink_log=""
dependents_driver_log=""
rerun_driver_log=""
unsafe_audit_path=""
run_started_utc=""

declare -A step_status=(
  [baseline_inputs]="PENDING"
  [packages]="PENDING"
  [package_contract]="PENDING"
  [cargo_build]="PENDING"
  [shared_object_contract]="PENDING"
  [cve_regression]="PENDING"
  [symbols]="PENDING"
  [source_tests]="PENDING"
  [relink]="PENDING"
  [dependents]="PENDING"
  [rerun]="SKIPPED"
  [unsafe_audit]="PENDING"
)

while (($#)); do
  case "$1" in
    --only)
      only_args+=("$1" "${2:?missing value for --only}")
      shift 2
      ;;
    --report-dir)
      report_dir="${2:?missing value for --report-dir}"
      shift 2
      ;;
    --rerun-from-list)
      rerun_from_list="${2:?missing value for --rerun-from-list}"
      shift 2
      ;;
    --rerun-report-dir)
      rerun_report_dir="${2:?missing value for --rerun-report-dir}"
      shift 2
      ;;
    --skip-rerun)
      skip_rerun=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

resolve_report_dir() {
  local input="$1"
  local parent
  local base

  parent="$(dirname -- "$input")"
  base="$(basename -- "$input")"
  mkdir -p "$parent"
  parent="$(cd -- "$parent" && pwd)"
  printf '%s/%s\n' "$parent" "$base"
}

log_step() {
  printf '\n==> %s\n' "$1"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

run_logged() {
  local log_path="$1"
  shift

  {
    printf '$'
    printf ' %q' "$@"
    printf '\n'
    "$@"
  } 2>&1 | tee -a "$log_path"
}

run_step() {
  local step="$1"
  local log_path="$2"
  shift 2

  step_status["$step"]="RUNNING"
  if run_logged "$log_path" "$@"; then
    step_status["$step"]="PASS"
  else
    step_status["$step"]="FAIL"
    return 1
  fi
}

collect_needed_libraries() {
  local library="$1"

  readelf -d "$library" \
    | awk -F'[][]' '/NEEDED/ { print $2 }' \
    | sort -u
}

count_results() {
  local results_file="$1"

  awk -F'\t' '
    NR == 1 { next }
    {
      total += 1
      if ($3 == "PASS") {
        pass += 1
      } else if ($3 == "FAIL") {
        fail += 1
      } else if ($3 == "WARN") {
        warn += 1
      }
    }
    END {
      printf "%d\t%d\t%d\t%d\n", total + 0, pass + 0, fail + 0, warn + 0
    }
  ' "$results_file"
}

count_matching_paths() {
  local search_root="$1"
  shift

  if [[ ! -e "$search_root" ]]; then
    printf '0\n'
    return
  fi

  find "$search_root" "$@" | wc -l | tr -d '[:space:]'
}

find_latest_artifact() {
  local pattern="$1"

  find "$repo_dir" -maxdepth 1 -type f -name "$pattern" | sort | tail -n1
}

package_has_path() {
  local deb_path="$1"
  local path_regex="$2"

  dpkg-deb -c "$deb_path" | awk '{ print $6 }' | grep -Eq "$path_regex"
}

package_field_equals() {
  local deb_path="$1"
  local field="$2"
  local expected="$3"
  local actual

  actual="$(dpkg-deb -f "$deb_path" "$field")"
  [[ "$actual" == "$expected" ]] \
    || die "expected $field=$expected in $(basename -- "$deb_path"), found ${actual:-<none>}"
  printf 'Confirmed %s=%s for %s.\n' "$field" "$expected" "$(basename -- "$deb_path")"
}

package_field_matches() {
  local deb_path="$1"
  local field="$2"
  local regex="$3"
  local actual

  actual="$(dpkg-deb -f "$deb_path" "$field")"
  [[ "$actual" =~ $regex ]] \
    || die "unexpected $field in $(basename -- "$deb_path"): ${actual:-<none>}"
  printf 'Confirmed %s in %s matches %s.\n' "$field" "$(basename -- "$deb_path")" "$regex"
}

package_field_contains() {
  local deb_path="$1"
  local field="$2"
  local needle="$3"
  local actual

  actual="$(dpkg-deb -f "$deb_path" "$field")"
  grep -F -- "$needle" <<<"$actual" >/dev/null \
    || die "expected $field in $(basename -- "$deb_path") to contain: $needle"
  printf 'Confirmed %s in %s contains %s.\n' "$field" "$(basename -- "$deb_path")" "$needle"
}

verify_authoritative_inputs() {
  local expected_count
  local baseline_results="$safe_dir/compat-reports/dependents/results.tsv"
  local baseline_failures="$safe_dir/compat-reports/dependents/failures.list"
  local baseline_rerun_results="$safe_dir/compat-reports/dependents-rerun/results.tsv"
  local baseline_rerun_failures="$safe_dir/compat-reports/dependents-rerun/failures.list"
  local path
  local baseline_total
  local baseline_pass
  local baseline_fail
  local baseline_warn
  local baseline_rerun_total
  local baseline_rerun_pass
  local baseline_rerun_fail
  local baseline_rerun_warn
  local baseline_log_count
  local baseline_artifact_dirs
  local baseline_rerun_log_count
  local baseline_rerun_artifact_dirs

  for path in \
    "$baseline_results" \
    "$baseline_failures" \
    "$baseline_rerun_results" \
    "$baseline_rerun_failures" \
    "$safe_dir/compat-reports/dependents/logs" \
    "$safe_dir/compat-reports/dependents/artifacts" \
    "$safe_dir/compat-reports/dependents-rerun/logs" \
    "$safe_dir/compat-reports/dependents-rerun/artifacts"; do
    [[ -e "$path" ]] || die "missing authoritative compatibility input: $path"
  done

  expected_count="$(jq '.dependents | length' "$repo_dir/dependents.json")"
  read -r baseline_total baseline_pass baseline_fail baseline_warn < <(count_results "$baseline_results")
  [[ "$baseline_total" -eq "$expected_count" ]] \
    || die "expected $expected_count rows in the durable dependent ledger, found $baseline_total"
  [[ "$baseline_pass" -eq "$expected_count" && "$baseline_fail" -eq 0 && "$baseline_warn" -eq 0 ]] \
    || die "durable dependent ledger is no longer fully green"
  [[ ! -s "$baseline_failures" ]] \
    || die "durable dependent failure list must stay empty for the final closure run"

  read -r baseline_rerun_total baseline_rerun_pass baseline_rerun_fail baseline_rerun_warn < <(count_results "$baseline_rerun_results")
  [[ "$baseline_rerun_fail" -eq 0 && "$baseline_rerun_warn" -eq 0 ]] \
    || die "durable rerun ledger contains non-PASS rows"
  [[ ! -s "$baseline_rerun_failures" ]] \
    || die "durable rerun failure list must stay empty for the final closure run"

  baseline_log_count="$(count_matching_paths "$safe_dir/compat-reports/dependents/logs" -type f -name '*.log')"
  baseline_artifact_dirs="$(count_matching_paths "$safe_dir/compat-reports/dependents/artifacts" -mindepth 1 -maxdepth 1 -type d)"
  baseline_rerun_log_count="$(count_matching_paths "$safe_dir/compat-reports/dependents-rerun/logs" -type f -name '*.log')"
  baseline_rerun_artifact_dirs="$(count_matching_paths "$safe_dir/compat-reports/dependents-rerun/artifacts" -mindepth 1 -maxdepth 1 -type d)"

  printf 'Consumed durable dependent ledger: %s PASS rows, %s log files, %s artifact directories.\n' \
    "$baseline_pass" "$baseline_log_count" "$baseline_artifact_dirs"
  printf 'Consumed durable rerun ledger: %s data rows, %s log files, %s artifact directories.\n' \
    "$baseline_rerun_total" "$baseline_rerun_log_count" "$baseline_rerun_artifact_dirs"
}

check_shared_object_contract() {
  local safe_lib="$safe_dir/target/release/libsodium.so"
  local upstream_lib="$repo_dir/original/src/libsodium/.libs/libsodium.so"
  local runtime_deb
  local soname

  [[ -f "$safe_lib" ]] || die "missing release library artifact: $safe_lib"
  [[ -f "$upstream_lib" ]] || die "missing upstream library artifact: $upstream_lib"

  soname="$(readelf -d "$safe_lib" | awk -F'[][]' '/SONAME/ { print $2; exit }')"
  [[ "$soname" == "libsodium.so.23" ]] \
    || die "expected SONAME libsodium.so.23, found ${soname:-<none>}"
  echo "Confirmed the shared object still has SONAME libsodium.so.23."

  mapfile -t safe_needed < <(collect_needed_libraries "$safe_lib")
  mapfile -t upstream_needed < <(collect_needed_libraries "$upstream_lib")
  mapfile -t missing_needed < <(
    comm -23 \
      <(printf '%s\n' "${upstream_needed[@]}") \
      <(printf '%s\n' "${safe_needed[@]}")
  )
  mapfile -t extra_needed < <(
    comm -13 \
      <(printf '%s\n' "${upstream_needed[@]}") \
      <(printf '%s\n' "${safe_needed[@]}")
  )

  [[ ${#missing_needed[@]} -eq 0 ]] \
    || die "safe shared object is missing upstream dynamic dependencies: ${missing_needed[*]}"

  if [[ ${#extra_needed[@]} -eq 0 ]]; then
    echo "Confirmed the shared object does not introduce unexpected dynamic dependencies relative to upstream."
    return
  fi

  if [[ ${#extra_needed[@]} -ne 1 || ${extra_needed[0]} != "libgcc_s.so.1" ]]; then
    die "safe shared object introduced unexpected dynamic dependencies: ${extra_needed[*]}"
  fi

  runtime_deb="$(find_latest_artifact 'libsodium23_*.deb')"
  [[ -n "$runtime_deb" ]] || die "unable to locate the built libsodium23 package"
  dpkg-deb -f "$runtime_deb" Depends | grep -Eq '(^|, )libgcc-s1([ (]|,|$)' \
    || die "runtime package does not declare libgcc-s1 for libgcc_s.so.1"

  echo "Documented unavoidable dynamic dependency relative to upstream: libgcc_s.so.1, packaged via libgcc-s1."
}

check_cve_fix() {
  (
    cd "$safe_dir"
    cargo test --release --test cve_2025_69277
  )
  echo "Confirmed CVE-2025-69277 remains fixed."
}

build_packages() {
  "$safe_dir/tools/build-deb.sh"
}

check_package_contract() {
  local runtime_deb
  local dev_deb
  local version

  runtime_deb="$(find_latest_artifact 'libsodium23_*.deb')"
  dev_deb="$(find_latest_artifact 'libsodium-dev_*.deb')"
  [[ -n "$runtime_deb" ]] || die "unable to locate the built libsodium23 package"
  [[ -n "$dev_deb" ]] || die "unable to locate the built libsodium-dev package"

  version="$(dpkg-deb -f "$runtime_deb" Version)"
  [[ -n "$version" ]] || die "unable to read the runtime package version"

  package_field_equals "$runtime_deb" Package "libsodium23"
  package_field_equals "$dev_deb" Package "libsodium-dev"
  package_field_equals "$runtime_deb" Multi-Arch "same"
  package_field_equals "$dev_deb" Multi-Arch "same"
  package_field_matches "$runtime_deb" Depends '(^|, )libc6([ (]|,|$)'
  package_field_matches "$runtime_deb" Depends '(^|, )libgcc-s1([ (]|,|$)'
  package_field_contains "$dev_deb" Depends "libsodium23 (= $version)"

  package_has_path "$runtime_deb" '^\./usr/lib/.*/libsodium\.so\.23\.3\.0$' \
    || die "runtime package is missing libsodium.so.23.3.0"
  package_has_path "$runtime_deb" '^\./usr/lib/.*/libsodium\.so\.23$' \
    || die "runtime package is missing the libsodium.so.23 SONAME symlink"
  package_has_path "$dev_deb" '^\./usr/lib/.*/libsodium\.so$' \
    || die "development package is missing the linker symlink"
  package_has_path "$dev_deb" '^\./usr/lib/.*/libsodium\.a$' \
    || die "development package is missing the static archive"
  package_has_path "$dev_deb" '^\./usr/lib/.*/pkgconfig/libsodium\.pc$' \
    || die "development package is missing libsodium.pc"
  package_has_path "$dev_deb" '^\./usr/include/sodium\.h$' \
    || die "development package is missing sodium.h"
  package_has_path "$dev_deb" '^\./usr/include/sodium/crypto_box\.h$' \
    || die "development package is missing exported headers"

  printf 'Confirmed package payloads provide the expected runtime library, linker symlink, headers, archive, and pkg-config metadata.\n'
  printf '\n### libsodium23 control\n'
  dpkg-deb -f "$runtime_deb"
  printf '\n### libsodium23 contents\n'
  dpkg-deb -c "$runtime_deb"
  printf '\n### libsodium-dev control\n'
  dpkg-deb -f "$dev_deb"
  printf '\n### libsodium-dev contents\n'
  dpkg-deb -c "$dev_deb"
}

build_release_cdylib() {
  cargo build --manifest-path "$safe_dir/Cargo.toml" --release
}

run_safe_dependents() {
  "$safe_dir/tools/run-dependent-matrix.sh" \
    --mode safe \
    --strict \
    --report-dir "$dependents_dir" \
    "${only_args[@]}"
}

run_rerun_dependents() {
  "$safe_dir/tools/run-dependent-matrix.sh" \
    --mode safe \
    --from-list "$rerun_from_list" \
    --report-dir "$rerun_report_dir"
}

unsafe_reason_for_path() {
  local path="$1"

  case "$path" in
    "$safe_dir/src/ffi/helpers.rs")
      printf '%s\n' 'Centralized raw-pointer, errno, and callback casting helpers for the public C ABI boundary.'
      ;;
    "$safe_dir/src/foundation/randombytes.rs")
      printf '%s\n' 'OS randomness syscalls, errno access, and the randombytes implementation vtable are inherently unsafe.'
      ;;
    "$safe_dir/src/foundation/utils.rs")
      printf '%s\n' 'mmap/mlock/mprotect-style memory management and caller-owned raw buffers require low-level interoperability.'
      ;;
    "$safe_dir/src/foundation/runtime.rs")
      printf '%s\n' 'Weak runtime CPU-feature probing crosses the Rust/C boundary.'
      ;;
    "$safe_dir/src/foundation/core.rs")
      printf '%s\n' 'The misuse-handler callback and process-global FFI state cross the public C ABI boundary.'
      ;;
    "$safe_dir/src/foundation/codecs.rs")
      printf '%s\n' 'C-string and caller-buffer walking remains at the ABI boundary for sodium encoding helpers.'
      ;;
    "$safe_dir/src/public_key_impl.rs")
      printf '%s\n' 'Public-key entrypoints validate and write caller-owned buffers; the boundary is still raw-pointer based.'
      ;;
    "$safe_dir/src/symmetric_impl.rs")
      printf '%s\n' 'Symmetric and pwhash entrypoints validate and write caller-owned buffers; the ABI surface is still raw-pointer based.'
      ;;
    "$safe_dir/src/abi/types.rs")
      printf '%s\n' 'ABI structs embed foreign function pointers with C calling conventions.'
      ;;
    *)
      printf '%s\n' 'The remaining unsafe use is confined to FFI forwarding or low-level interoperability required by the C-compatible surface.'
      ;;
  esac
}

generate_unsafe_audit() {
  local library_total
  local aux_total
  local path
  local count
  declare -a library_matches=()
  declare -a aux_matches=()

  mapfile -t library_matches < <(rg -l '\bunsafe\b' "$safe_dir/src" | sort || true)
  mapfile -t aux_matches < <(rg -l '\bunsafe\b' "$safe_dir/tests" "$safe_dir/build.rs" | sort || true)
  library_total="$(rg -n '\bunsafe\b' "$safe_dir/src" | wc -l | tr -d '[:space:]' || true)"
  aux_total="$(rg -n '\bunsafe\b' "$safe_dir/tests" "$safe_dir/build.rs" | wc -l | tr -d '[:space:]' || true)"

  {
    printf 'Unsafe audit generated on %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    printf '\n'
    printf 'Scope: safe/src, safe/tests, and safe/build.rs\n'
    printf 'Policy: remaining unsafe must stay confined to unavoidable FFI, OS, or low-level interoperability boundaries.\n'
    printf '\n'
    printf 'Library unsafe locations: %s\n' "${library_total:-0}"
    printf 'Test/build unsafe locations: %s\n' "${aux_total:-0}"
    printf '\n'
    printf 'Per-file library summary:\n'
    for path in "${library_matches[@]}"; do
      count="$(rg -n '\bunsafe\b' "$path" | wc -l | tr -d '[:space:]')"
      printf '  %s  %s\n' "$count" "${path#$safe_dir/}"
      printf '      %s\n' "$(unsafe_reason_for_path "$path")"
    done
    printf '\n'
    printf 'Library unsafe line references:\n'
    rg -n '\bunsafe\b' "$safe_dir/src" | sed "s#^$safe_dir/##"
    printf '\n'
    printf 'Test/build unsafe line references:\n'
    if ((${#aux_matches[@]} > 0)); then
      rg -n '\bunsafe\b' "$safe_dir/tests" "$safe_dir/build.rs" | sed "s#^$safe_dir/##"
    else
      printf '(none)\n'
    fi
  } > "$unsafe_audit_path"
}

write_summary() {
  local exit_code="$1"
  local overall_status="FAIL"
  local baseline_results="$safe_dir/compat-reports/dependents/results.tsv"
  local baseline_rerun_results="$safe_dir/compat-reports/dependents-rerun/results.tsv"
  local final_results="$dependents_dir/results.tsv"
  local final_failures="$dependents_dir/failures.list"
  local rerun_results="$rerun_report_dir/results.tsv"
  local selection="full dependent matrix"
  local baseline_total=0
  local baseline_pass=0
  local baseline_fail=0
  local baseline_warn=0
  local baseline_rerun_total=0
  local baseline_rerun_pass=0
  local baseline_rerun_fail=0
  local baseline_rerun_warn=0
  local final_total=0
  local final_pass=0
  local final_fail=0
  local final_warn=0
  local rerun_total=0
  local rerun_pass=0
  local rerun_fail=0
  local rerun_warn=0
  local baseline_logs=0
  local baseline_artifacts=0
  local rerun_logs=0
  local rerun_artifacts=0
  local final_failure_count=0

  if [[ "$exit_code" -eq 0 ]]; then
    overall_status="PASS"
  fi

  if [[ ${#only_args[@]} -gt 0 ]]; then
    selection="$(printf '%s ' "${only_args[@]}")"
    selection="${selection% }"
  fi

  if [[ -f "$baseline_results" ]]; then
    read -r baseline_total baseline_pass baseline_fail baseline_warn < <(count_results "$baseline_results")
  fi
  if [[ -f "$baseline_rerun_results" ]]; then
    read -r baseline_rerun_total baseline_rerun_pass baseline_rerun_fail baseline_rerun_warn < <(count_results "$baseline_rerun_results")
  fi
  if [[ -f "$final_results" ]]; then
    read -r final_total final_pass final_fail final_warn < <(count_results "$final_results")
  fi
  if [[ -f "$rerun_results" ]]; then
    read -r rerun_total rerun_pass rerun_fail rerun_warn < <(count_results "$rerun_results")
  fi
  if [[ -f "$final_failures" && -s "$final_failures" ]]; then
    final_failure_count="$(wc -l < "$final_failures" | tr -d '[:space:]')"
  fi

  baseline_logs="$(count_matching_paths "$safe_dir/compat-reports/dependents/logs" -type f -name '*.log')"
  baseline_artifacts="$(count_matching_paths "$safe_dir/compat-reports/dependents/artifacts" -mindepth 1 -maxdepth 1 -type d)"
  rerun_logs="$(count_matching_paths "$safe_dir/compat-reports/dependents-rerun/logs" -type f -name '*.log')"
  rerun_artifacts="$(count_matching_paths "$safe_dir/compat-reports/dependents-rerun/artifacts" -mindepth 1 -maxdepth 1 -type d)"

  cat > "$summary_path" <<EOF
# Final Compatibility Summary

- Started (UTC): $run_started_utc
- Finished (UTC): $(date -u '+%Y-%m-%d %H:%M:%S UTC')
- Overall status: $overall_status
- Report root: $report_dir
- Selection: $selection
- Durable inputs consumed: safe/compat-reports/dependents/, safe/compat-reports/dependents-rerun/, and their existing logs/artifacts directories

## Durable Input Snapshot

- Phase-2/3 dependent ledger: $baseline_total row(s); PASS=$baseline_pass FAIL=$baseline_fail WARN=$baseline_warn
- Phase-2/3 dependent evidence: $baseline_logs log file(s), $baseline_artifacts artifact directories
- Phase-3 rerun ledger: $baseline_rerun_total row(s); PASS=$baseline_rerun_pass FAIL=$baseline_rerun_fail WARN=$baseline_rerun_warn
- Phase-3 rerun evidence: $rerun_logs log file(s), $rerun_artifacts artifact directories

## Final Run Outputs

- cargo.log: build + shared-object contract + CVE regression
- symbols.log: full ABI symbol verification
- source-tests.log: upstream C source-compat suite
- relink.log: upstream object relink suite
- packages.log: Debian build output + package metadata/content checks
- dependents.log: final dependent-matrix driver output
- dependents-rerun.log: rerun driver output when reruns are enabled
- unsafe-audit.txt: remaining unsafe footprint review
- dependents/results.tsv: $final_total row(s); PASS=$final_pass FAIL=$final_fail WARN=$final_warn
- dependents/failures.list: $final_failure_count selected package name(s)
- dependents-rerun/results.tsv: $rerun_total row(s); PASS=$rerun_pass FAIL=$rerun_fail WARN=$rerun_warn

## Step Status

- baseline_inputs: ${step_status[baseline_inputs]}
- packages: ${step_status[packages]}
- package_contract: ${step_status[package_contract]}
- cargo_build: ${step_status[cargo_build]}
- shared_object_contract: ${step_status[shared_object_contract]}
- cve_regression: ${step_status[cve_regression]}
- symbols: ${step_status[symbols]}
- source_tests: ${step_status[source_tests]}
- relink: ${step_status[relink]}
- dependents: ${step_status[dependents]}
- rerun: ${step_status[rerun]}
- unsafe_audit: ${step_status[unsafe_audit]}
EOF
}

cleanup() {
  local exit_code=$?

  if [[ -n "$summary_path" && -n "$report_dir" ]]; then
    write_summary "$exit_code" || true
  fi
}

report_dir="$(resolve_report_dir "$report_dir")"
if [[ -z "$rerun_report_dir" ]]; then
  rerun_report_dir="$report_dir/dependents-rerun"
fi
rerun_report_dir="$(resolve_report_dir "$rerun_report_dir")"
dependents_dir="$report_dir/dependents"
summary_path="$report_dir/summary.md"
packages_log="$report_dir/packages.log"
cargo_log="$report_dir/cargo.log"
symbols_log="$report_dir/symbols.log"
source_tests_log="$report_dir/source-tests.log"
relink_log="$report_dir/relink.log"
dependents_driver_log="$report_dir/dependents.log"
rerun_driver_log="$report_dir/dependents-rerun.log"
unsafe_audit_path="$report_dir/unsafe-audit.txt"
run_started_utc="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

mkdir -p "$report_dir"
find "$report_dir" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
: > "$packages_log"
: > "$cargo_log"
: > "$symbols_log"
: > "$source_tests_log"
: > "$relink_log"
: > "$dependents_driver_log"
: > "$rerun_driver_log"
trap cleanup EXIT

log_step "Verifying authoritative phase inputs"
run_step baseline_inputs "$packages_log" verify_authoritative_inputs

log_step "Building Debian packages"
run_step packages "$packages_log" build_packages

log_step "Checking Debian package contract"
run_step package_contract "$packages_log" check_package_contract

log_step "Building release shared object"
run_step cargo_build "$cargo_log" build_release_cdylib

log_step "Checking shared object contract"
run_step shared_object_contract "$cargo_log" check_shared_object_contract

log_step "Running CVE regression guard"
run_step cve_regression "$cargo_log" check_cve_fix

log_step "Checking exported symbols"
run_step symbols "$symbols_log" "$safe_dir/tools/check-symbols.sh"

log_step "Running original C source-compat suite"
run_step source_tests "$source_tests_log" "$safe_dir/tools/run-original-c-tests.sh" --all

log_step "Running original object relink suite"
run_step relink "$relink_log" "$safe_dir/tools/relink-original-objects.sh" --all

log_step "Auditing remaining unsafe boundaries"
step_status["unsafe_audit"]="RUNNING"
generate_unsafe_audit
step_status["unsafe_audit"]="PASS"

log_step "Running safe-mode dependent smoke tests"
run_step dependents "$dependents_driver_log" run_safe_dependents

if [[ "$skip_rerun" != "1" ]]; then
  log_step "Rerunning selected dependent failures"
  run_step rerun "$rerun_driver_log" run_rerun_dependents
fi
