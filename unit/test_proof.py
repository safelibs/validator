from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

from tools import ValidatorError
from tools import proof
from tools import verify_proof_artifacts
from tools.inventory import load_manifest
from tools.testcases import TestcaseManifest, load_testcase_manifest


FIXTURES = Path(__file__).resolve().parent / "fixtures"


class ProofTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name)
        self.artifacts_root = self.root / "artifacts"
        self.config = load_manifest(FIXTURES / "original-only-manifest.yml")
        self.tests_root = FIXTURES / "original-only-tests"
        self.case_manifest = load_testcase_manifest(
            self.tests_root / "original-demo" / "testcases.yml",
            library="original-demo",
        )

    def write_cast(self, case_id: str, *, events: list[object] | None = None) -> None:
        cast_path = self.artifacts_root / "casts" / "original-demo" / f"{case_id}.cast"
        cast_path.parent.mkdir(parents=True, exist_ok=True)
        events = events if events is not None else [[0.1, "o", f"{case_id}\n"]]
        lines = [
            json.dumps({"version": 2, "width": 120, "height": 40}),
            *[json.dumps(event) if not isinstance(event, str) else event for event in events],
        ]
        cast_path.write_text("\n".join(lines) + "\n")

    def write_result(
        self,
        case_id: str,
        *,
        status: str = "passed",
        cast: bool = True,
        updates: dict[str, object] | None = None,
    ) -> None:
        cases = {case.id: case for case in self.case_manifest.testcases}
        testcase = cases[case_id]
        result_path = self.artifacts_root / "results" / "original-demo" / f"{case_id}.json"
        log_path = self.artifacts_root / "logs" / "original-demo" / f"{case_id}.log"
        result_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.write_text(f"log for {case_id}\n")
        if cast:
            self.write_cast(case_id)
        payload: dict[str, object] = {
            "schema_version": 2,
            "library": "original-demo",
            "mode": "original",
            "testcase_id": testcase.id,
            "title": testcase.title,
            "description": testcase.description,
            "kind": testcase.kind,
            "client_application": testcase.client_application,
            "tags": list(testcase.tags),
            "requires": list(testcase.requires),
            "status": status,
            "started_at": "2026-04-18T00:00:00Z",
            "finished_at": "2026-04-18T00:00:01Z",
            "duration_seconds": 1.0,
            "result_path": f"results/original-demo/{case_id}.json",
            "log_path": f"logs/original-demo/{case_id}.log",
            "cast_path": f"casts/original-demo/{case_id}.cast" if cast else None,
            "exit_code": 0 if status == "passed" else 1,
            "command": list(testcase.command),
            "apt_packages": list(self.case_manifest.apt_packages),
            "override_debs_installed": False,
        }
        if updates:
            payload.update(updates)
        result_path.write_text(json.dumps(payload, indent=2) + "\n")

    def write_library(self, *, cast: bool = True) -> None:
        for testcase in self.case_manifest.testcases:
            self.write_result(testcase.id, cast=cast)
        self.write_summary(cast=cast)

    def write_summary(self, *, cast: bool = True, updates: dict[str, object] | None = None) -> None:
        summary_path = self.artifacts_root / "results" / "original-demo" / "summary.json"
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        payload: dict[str, object] = {
            "schema_version": 2,
            "library": "original-demo",
            "mode": "original",
            "cases": 2,
            "source_cases": 1,
            "usage_cases": 1,
            "passed": 2,
            "failed": 0,
            "casts": 2 if cast else 0,
            "duration_seconds": 2.0,
        }
        if updates:
            payload.update(updates)
        summary_path.write_text(json.dumps(payload, indent=2) + "\n")

    def build(self, **kwargs: object) -> dict[str, object]:
        return proof.build_proof(
            self.config,
            artifact_root=self.artifacts_root,
            tests_root=self.tests_root,
            **kwargs,
        )

    def test_original_only_proof_options_require_tests_root(self) -> None:
        with self.assertRaisesRegex(ValidatorError, "tests_root"):
            proof.build_proof(
                self.config,
                artifact_root=self.artifacts_root,
                record_casts_expected=True,
            )

    def test_valid_original_only_proof_generation(self) -> None:
        self.write_library()

        result = self.build(record_casts_expected=True)

        self.assertEqual(result["proof_version"], 2)
        self.assertEqual(result["mode"], "original")
        self.assertEqual(result["included_libraries"], ["original-demo"])
        self.assertEqual(result["totals"]["cases"], 2)
        self.assertEqual(result["totals"]["source_cases"], 1)
        self.assertEqual(result["totals"]["usage_cases"], 1)
        self.assertEqual(result["totals"]["passed"], 2)
        self.assertEqual(result["totals"]["failed"], 0)
        self.assertEqual(result["totals"]["casts"], 2)
        self.assertEqual(result["libraries"][0]["cases"][0]["cast_events"], 1)

    def test_result_status_must_be_passed_or_failed(self) -> None:
        for status in ("skipped", "warned", "excluded"):
            with self.subTest(status=status):
                self.setUp()
                self.write_library()
                self.write_result("source-echo-roundtrip", status=status)
                with self.assertRaisesRegex(ValidatorError, "status must be passed or failed"):
                    self.build()

    def test_result_schema_and_identity_checks_are_enforced(self) -> None:
        mutations = [
            ("schema_version", 1, "schema_version must be 2"),
            ("mode", "replacement", "mode must be original"),
            ("result_path", "results/original-demo/wrong.json", "result_path must equal"),
            ("log_path", "logs/original-demo/wrong.log", "log_path must equal"),
            ("started_at", "2026-04-18T00:00:00+00:00", "ending in Z"),
            ("started_at", "not-a-dateZ", "UTC ISO-8601"),
            ("finished_at", "2026-13-18T00:00:01Z", "UTC ISO-8601"),
            ("duration_seconds", -1, "duration_seconds must be a non-negative number"),
            ("exit_code", 1.5, "exit_code must be an integer"),
            ("override_debs_installed", "no", "must be a boolean"),
        ]
        for field, value, message in mutations:
            with self.subTest(field=field):
                self.setUp()
                self.write_library()
                self.write_result("source-echo-roundtrip", updates={field: value})
                with self.assertRaisesRegex(ValidatorError, message):
                    self.build()

    def test_apt_package_and_testcase_metadata_mismatches_are_rejected(self) -> None:
        cases = [
            ({"apt_packages": ["demo-dev", "demo-runtime"]}, "apt_packages mismatch"),
            ({"title": "Different"}, "title mismatch"),
            ({"command": ["bash", "-c", "true"]}, "command mismatch"),
        ]
        for updates, message in cases:
            with self.subTest(updates=updates):
                self.setUp()
                self.write_library()
                self.write_result("source-echo-roundtrip", updates=updates)
                with self.assertRaisesRegex(ValidatorError, message):
                    self.build()

    def test_missing_log_and_cast_requirements_are_rejected(self) -> None:
        self.write_library()
        (self.artifacts_root / "logs" / "original-demo" / "source-echo-roundtrip.log").unlink()
        with self.assertRaisesRegex(ValidatorError, "log_path does not exist"):
            self.build()

        self.setUp()
        self.write_library(cast=False)
        with self.assertRaisesRegex(ValidatorError, "cast_path is required"):
            self.build(record_casts_expected=True)

    def test_cast_validation_rejects_bad_casts(self) -> None:
        cases = [
            ([[0.1, "i", "x"]], "event type"),
            ([[-0.1, "o", "x"]], "non-negative"),
            ([], "at least one output event"),
            (["not json"], "invalid cast event JSON"),
        ]
        for events, message in cases:
            with self.subTest(message=message):
                self.setUp()
                self.write_library()
                self.write_cast("source-echo-roundtrip", events=events)
                with self.assertRaisesRegex(ValidatorError, message):
                    self.build()

    def test_summary_must_match_case_results(self) -> None:
        self.write_library()
        self.write_summary(updates={"passed": 1, "failed": 1})

        with self.assertRaisesRegex(ValidatorError, "summary passed mismatch"):
            self.build()

    def test_symlink_escape_is_rejected(self) -> None:
        self.write_library()
        outside = self.root / "outside"
        outside.mkdir()
        outside_result = outside / "source-echo-roundtrip.json"
        original_result = self.artifacts_root / "results" / "original-demo" / "source-echo-roundtrip.json"
        outside_result.write_text(original_result.read_text())
        original_result.unlink()
        original_result.symlink_to(outside_result)

        with self.assertRaisesRegex(ValidatorError, "result path must stay within the artifact root"):
            self.build()

    def test_proof_validation_does_not_mutate_artifacts(self) -> None:
        self.write_library()
        result_path = self.artifacts_root / "results" / "original-demo" / "source-echo-roundtrip.json"
        summary_path = self.artifacts_root / "results" / "original-demo" / "summary.json"
        before_result = result_path.read_text()
        before_summary = summary_path.read_text()

        self.build()

        self.assertEqual(result_path.read_text(), before_result)
        self.assertEqual(summary_path.read_text(), before_summary)

    def test_subset_exclusion_and_threshold_checks(self) -> None:
        self.write_library()

        subset = self.build(libraries=["original-demo"])
        self.assertEqual(subset["included_libraries"], ["original-demo"])

        excluded = self.build(excluded_libraries={"original-demo": "hosted elsewhere"})
        self.assertEqual(excluded["included_libraries"], [])
        self.assertEqual(excluded["excluded_libraries"], [{"library": "original-demo", "note": "hosted elsewhere"}])

        with self.assertRaisesRegex(ValidatorError, "total case threshold"):
            self.build(min_total_cases=3)

    def test_cli_validates_output_paths_and_writes_proof(self) -> None:
        self.write_library()
        exit_code = verify_proof_artifacts.main(
            [
                "--config",
                str(FIXTURES / "original-only-manifest.yml"),
                "--tests-root",
                str(self.tests_root),
                "--artifact-root",
                str(self.artifacts_root),
                "--proof-output",
                "proof/proof.json",
                "--record-casts",
            ]
        )

        self.assertEqual(exit_code, 0)
        proof_path = self.artifacts_root / "proof" / "proof.json"
        self.assertTrue(proof_path.is_file())
        self.assertEqual(json.loads(proof_path.read_text())["proof_version"], 2)

        original_cwd = Path.cwd()
        os.chdir(self.root)
        self.addCleanup(os.chdir, original_cwd)
        for output in ("../proof.json", "proof\\bad.json", "/tmp/proof.json", "proof//bad.json", "proof/./bad.json"):
            with self.subTest(output=output):
                with self.assertRaisesRegex(ValidatorError, "--proof-output"):
                    verify_proof_artifacts.main(
                        [
                            "--config",
                            str(FIXTURES / "original-only-manifest.yml"),
                            "--tests-root",
                            str(self.tests_root),
                            "--artifact-root",
                            str(self.artifacts_root),
                            "--proof-output",
                            output,
                        ]
                    )

    def test_duplicate_exclusions_are_rejected_before_config_load(self) -> None:
        with self.assertRaisesRegex(ValidatorError, "--exclude-library must not contain duplicates"):
            verify_proof_artifacts.main(
                [
                    "--config",
                    str(self.root / "missing.yml"),
                    "--tests-root",
                    str(self.tests_root),
                    "--artifact-root",
                    str(self.artifacts_root),
                    "--proof-output",
                    "proof/proof.json",
                    "--exclude-library",
                    "original-demo",
                    "--exclude-library",
                    "original-demo",
                ]
            )


if __name__ == "__main__":
    unittest.main()
