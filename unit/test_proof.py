from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

from tools import ValidatorError
from tools import proof
from tools import verify_proof_artifacts


class ProofTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name)
        self.artifacts_root = self.root / "artifacts"

    def manifest(self, *libraries: str) -> dict[str, object]:
        return {
            "repositories": [
                {
                    "name": library,
                    "validator": {"execution_strategy": "host-harness"},
                }
                for library in libraries
            ]
        }

    def write_cast(
        self,
        library: str,
        *,
        header: dict[str, object] | None = None,
        events: list[object] | None = None,
    ) -> None:
        cast_path = self.artifacts_root / "casts" / library / "safe.cast"
        cast_path.parent.mkdir(parents=True, exist_ok=True)
        header = header if header is not None else {"version": 2, "width": 120, "height": 40}
        events = events if events is not None else [[0.1, "o", "first\n"], [0.2, "o", "second\n"]]
        lines = [json.dumps(header), *[json.dumps(event) if not isinstance(event, str) else event for event in events]]
        cast_path.write_text("\n".join(lines) + "\n")

    def write_summary(
        self,
        library: str,
        mode: str,
        *,
        count: int,
        status: str = "passed",
        report_format: str = "imported-log-marker",
        selected: list[str] | None = None,
        passed: list[str] | None = None,
        failed: list[str] | None = None,
        warned: list[str] | None = None,
        skipped: list[str] | None = None,
        notes: str | None = None,
    ) -> None:
        selected = selected if selected is not None else [f"{library}-{mode}-{index}" for index in range(count)]
        if passed is None and failed is None and warned is None and skipped is None:
            passed = list(selected) if status == "passed" else selected[1:]
            failed = [] if status == "passed" else selected[:1]
        payload: dict[str, object] = {
            "summary_version": 1,
            "library": library,
            "mode": mode,
            "status": status,
            "report_format": report_format,
            "expected_dependents": count,
            "selected_dependents": selected,
            "passed_dependents": passed if passed is not None else [],
            "failed_dependents": failed if failed is not None else [],
            "warned_dependents": warned if warned is not None else [],
            "skipped_dependents": skipped if skipped is not None else [],
            "artifacts": {
                "console_log": f"downstream/{library}/{mode}/raw/console.log",
            },
        }
        if notes is not None:
            payload["notes"] = notes
        summary_path = self.artifacts_root / "downstream" / library / mode / "summary.json"
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        summary_path.write_text(json.dumps(payload, indent=2) + "\n")

    def write_result(
        self,
        library: str,
        mode: str,
        *,
        status: str = "passed",
        cast_path: str | None | object = None,
        log_path: str | None | object = None,
        summary_path: str | object | None = None,
        execution_strategy: str = "host-harness",
    ) -> None:
        result_path = self.artifacts_root / "results" / library / f"{mode}.json"
        result_path.parent.mkdir(parents=True, exist_ok=True)
        if log_path is None:
            log_path = f"logs/{library}/{mode}.log"
        if log_path is not False and isinstance(log_path, str):
            log_target = self.artifacts_root / log_path
            log_target.parent.mkdir(parents=True, exist_ok=True)
            log_target.write_text(f"log for {library}/{mode}\n")
        if cast_path is None and mode == "safe":
            cast_path = f"casts/{library}/safe.cast"
        if summary_path is None:
            summary_path = f"downstream/{library}/{mode}/summary.json"
        payload = {
            "library": library,
            "mode": mode,
            "execution_strategy": execution_strategy,
            "status": status,
            "started_at": "2026-04-12T00:00:00Z",
            "finished_at": "2026-04-12T00:00:01Z",
            "duration_seconds": 1.0,
            "log_path": log_path if log_path is not False else f"logs/{library}/{mode}.log",
            "cast_path": cast_path,
            "exit_code": 0 if status == "passed" else 1,
            "downstream_summary_path": summary_path,
        }
        result_path.write_text(json.dumps(payload, indent=2) + "\n")

    def write_library(
        self,
        library: str,
        *,
        original_count: int = 2,
        safe_count: int = 3,
        safe_status: str = "passed",
    ) -> None:
        self.write_cast(library)
        self.write_summary(library, "original", count=original_count)
        self.write_summary(library, "safe", count=safe_count, status=safe_status)
        self.write_result(library, "original", status="passed", cast_path=None)
        self.write_result(library, "safe", status=safe_status)

    def build(self, *libraries: str, **kwargs: object) -> dict[str, object]:
        return proof.build_proof(
            self.manifest(*libraries),
            artifact_root=self.artifacts_root,
            **kwargs,
        )

    def test_valid_full_proof_generation(self) -> None:
        self.write_library("alpha")
        self.write_library("beta", original_count=4, safe_count=5)

        result = self.build("alpha", "beta")

        self.assertEqual(result["included_libraries"], ["alpha", "beta"])
        self.assertEqual(result["totals"]["included_libraries"], 2)
        self.assertEqual(result["totals"]["result_runs"], 4)
        self.assertEqual(result["totals"]["safe_casts"], 2)
        self.assertEqual(result["totals"]["safe_workloads"], 8)
        self.assertEqual(result["totals"]["total_workloads"], 14)
        self.assertEqual(result["totals"]["report_formats"], ["imported-log-marker"])
        self.assertEqual(result["libraries"][0]["safe"]["cast_events"], 2)
        self.assertGreater(result["libraries"][0]["safe"]["cast_bytes"], 0)

    def test_result_identity_mismatches_are_rejected(self) -> None:
        cases = [
            ("library", "wrong", "library mismatch"),
            ("mode", "wrong", "mode mismatch"),
            ("execution_strategy", "container-image", "execution_strategy mismatch"),
        ]
        for field, value, message in cases:
            with self.subTest(field=field):
                self.setUp()
                self.write_library("alpha")
                path = self.artifacts_root / "results" / "alpha" / "safe.json"
                payload = json.loads(path.read_text())
                payload[field] = value
                path.write_text(json.dumps(payload, indent=2) + "\n")

                with self.assertRaisesRegex(ValidatorError, message):
                    self.build("alpha")

    def test_result_schema_checks_are_enforced(self) -> None:
        mutations = [
            ("status", "unknown", "status must be passed or failed"),
            ("started_at", "", "started_at must be a non-empty string"),
            ("finished_at", 123, "finished_at must be a non-empty string"),
            ("duration_seconds", -1, "duration_seconds must be a non-negative number"),
            ("exit_code", 1.2, "exit_code must be an integer"),
        ]
        for field, value, message in mutations:
            with self.subTest(field=field):
                self.setUp()
                self.write_library("alpha")
                path = self.artifacts_root / "results" / "alpha" / "safe.json"
                payload = json.loads(path.read_text())
                payload[field] = value
                path.write_text(json.dumps(payload, indent=2) + "\n")

                with self.assertRaisesRegex(ValidatorError, message):
                    self.build("alpha")

    def test_missing_or_wrong_log_path_is_rejected(self) -> None:
        self.write_library("alpha")
        path = self.artifacts_root / "results" / "alpha" / "safe.json"
        payload = json.loads(path.read_text())
        payload["log_path"] = "logs/alpha/not-safe.log"
        path.write_text(json.dumps(payload, indent=2) + "\n")

        with self.assertRaisesRegex(ValidatorError, "log_path must equal"):
            self.build("alpha")

        self.setUp()
        self.write_library("alpha")
        (self.artifacts_root / "logs" / "alpha" / "safe.log").unlink()
        with self.assertRaisesRegex(ValidatorError, "log_path does not exist|missing log"):
            self.build("alpha")

    def test_cast_validation_rejects_bad_casts(self) -> None:
        cases = [
            ({"version": 1, "width": 120, "height": 40}, [[0.1, "o", "x"]], "version must be 2"),
            ({"version": 2, "width": 120, "height": 40}, ["not json"], "invalid cast event JSON"),
            ({"version": 2, "width": 120, "height": 40}, ['[NaN, "o", "x"]'], "invalid cast event JSON"),
            ({"version": 2, "width": 120, "height": 40}, [[-0.1, "o", "x"]], "non-negative"),
            ({"version": 2, "width": 120, "height": 40}, [], "at least one output event"),
        ]
        for header, events, message in cases:
            with self.subTest(message=message):
                self.setUp()
                self.write_library("alpha")
                self.write_cast("alpha", header=header, events=events)
                with self.assertRaisesRegex(ValidatorError, message):
                    self.build("alpha")

    def test_missing_safe_cast_is_rejected(self) -> None:
        self.write_library("alpha")
        (self.artifacts_root / "casts" / "alpha" / "safe.cast").unlink()

        with self.assertRaisesRegex(ValidatorError, "missing safe cast"):
            self.build("alpha")

    def test_traversal_in_cast_or_summary_path_is_rejected(self) -> None:
        for field, value in (
            ("cast_path", "../outside.cast"),
            ("downstream_summary_path", "downstream/alpha/safe/../summary.json"),
        ):
            with self.subTest(field=field):
                self.setUp()
                self.write_library("alpha")
                path = self.artifacts_root / "results" / "alpha" / "safe.json"
                payload = json.loads(path.read_text())
                payload[field] = value
                path.write_text(json.dumps(payload, indent=2) + "\n")
                with self.assertRaisesRegex(ValidatorError, "artifact-root-relative|artifact root"):
                    self.build("alpha")

    def test_symlink_escape_is_rejected(self) -> None:
        outside = self.root / "outside"
        outside.mkdir()
        (outside / "file").write_text("outside\n")
        self.artifacts_root.mkdir(parents=True)
        (self.artifacts_root / "escape").symlink_to(outside, target_is_directory=True)

        with self.assertRaisesRegex(ValidatorError, "artifact root"):
            proof.validate_artifact_relative_path(
                "escape/file",
                field_name="cast_path",
                artifacts_root=self.artifacts_root,
                source_path=self.root / "source.json",
            )

    def test_summary_bucket_invariant_failure_is_rejected(self) -> None:
        self.write_library("alpha")
        self.write_summary(
            "alpha",
            "safe",
            count=2,
            selected=["one", "two"],
            passed=["one"],
            failed=[],
            warned=[],
            skipped=[],
        )

        with self.assertRaisesRegex(ValidatorError, "cover selected_dependents"):
            self.build("alpha")

    def test_setup_stage_failure_is_not_counted_as_proof_coverage(self) -> None:
        self.write_library("alpha")
        self.write_summary(
            "alpha",
            "safe",
            count=1,
            status="failed",
            selected=[],
            passed=[],
            failed=[],
            warned=[],
            skipped=[],
            notes="setup failed before selection",
        )
        self.write_result("alpha", "safe", status="failed")

        with self.assertRaisesRegex(ValidatorError, "proof coverage"):
            self.build("alpha")

    def test_workload_threshold_failure_is_rejected(self) -> None:
        self.write_library("alpha")

        with self.assertRaisesRegex(ValidatorError, "safe workload threshold"):
            self.build("alpha", min_safe_workloads=99)

    def test_subset_and_hosted_exclusion_proofs(self) -> None:
        self.write_library("alpha")
        self.write_library("beta")

        subset = self.build("alpha", "beta", libraries=["beta"])
        self.assertEqual(subset["included_libraries"], ["beta"])
        self.assertEqual(subset["totals"]["included_libraries"], 1)

        hosted = self.build(
            "alpha",
            "beta",
            excluded_libraries={"beta": "hosted exclusion note"},
        )
        self.assertEqual(hosted["included_libraries"], ["alpha"])
        self.assertEqual(
            hosted["excluded_libraries"],
            [{"library": "beta", "note": "hosted exclusion note"}],
        )

    def test_duplicate_exclusion_and_empty_note_are_rejected(self) -> None:
        with self.assertRaisesRegex(ValidatorError, "--exclude-library must not contain duplicates"):
            verify_proof_artifacts.main(
                [
                    "--config",
                    str(self.root / "missing.yml"),
                    "--artifact-root",
                    str(self.artifacts_root),
                    "--proof-output",
                    str(self.artifacts_root / "proof" / "proof.json"),
                    "--exclude-library",
                    "alpha",
                    "--exclude-library",
                    "alpha",
                ]
            )

        self.write_library("alpha")
        with self.assertRaisesRegex(ValidatorError, "non-empty note"):
            self.build("alpha", excluded_libraries={"alpha": ""})

    def test_cli_rejects_unsafe_proof_output_paths_before_writing(self) -> None:
        original_cwd = Path.cwd()
        self.artifacts_root.mkdir(parents=True, exist_ok=True)
        os.chdir(self.root)
        self.addCleanup(os.chdir, original_cwd)

        unsafe_outputs = [
            "artifacts/proof/../proof/traversal-ok.json",
            "artifacts/proof\\bad.json",
            "/tmp/proof.json",
            "artifacts//proof/bad.json",
            "artifacts/./proof/bad.json",
        ]
        for output in unsafe_outputs:
            with self.subTest(output=output):
                with self.assertRaisesRegex(ValidatorError, "--proof-output"):
                    verify_proof_artifacts.main(
                        [
                            "--config",
                            "missing.yml",
                            "--artifact-root",
                            "artifacts",
                            "--proof-output",
                            output,
                        ]
                    )

    def test_safe_failures_are_valid_when_artifacts_exist(self) -> None:
        self.write_library("alpha", safe_status="failed")

        result = self.build("alpha")

        self.assertEqual(result["libraries"][0]["safe"]["status"], "failed")
        self.assertEqual(result["totals"]["safe_workloads"], 3)

    def test_proof_validation_does_not_mutate_downstream_summaries(self) -> None:
        self.write_library("alpha")
        summary_path = self.artifacts_root / "downstream" / "alpha" / "safe" / "summary.json"
        before = summary_path.read_text()

        self.build("alpha")

        self.assertEqual(summary_path.read_text(), before)


if __name__ == "__main__":
    unittest.main()
