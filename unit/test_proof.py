from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import ValidatorError
from tools import proof
from tools import verify_proof_artifacts
from tools.testcases import load_testcase_manifest


FIXTURES = Path(__file__).resolve().parent / "fixtures"


def original_demo_config() -> dict[str, object]:
    return {
        "schema_version": 2,
        "suite": {
            "name": "ubuntu-24.04-original-apt",
            "image": "ubuntu:24.04",
            "apt_suite": "noble",
        },
        "libraries": [
            {
                "name": "original-demo",
                "apt_packages": ["demo-runtime", "demo-dev"],
                "testcases": str(FIXTURES / "original-only-tests" / "original-demo" / "testcases.yml"),
            }
        ],
    }


class RuntimePackageHeuristicTests(unittest.TestCase):
    def test_runtime_packages_keep_lib_so_packages_only(self) -> None:
        apt_packages = [
            "libfoo1",
            "libfoo-dev",
            "libfoo-doc",
            "libfoo-tools",
            "libfoo-progs",
            "libfoo-utils",
            "libfoo-tests",
            "gir1.2-foo-1.0",
            "python3-foo",
            "foo",
        ]
        self.assertEqual(proof.runtime_packages_from_apt_packages(apt_packages), ["libfoo1"])

    def test_runtime_packages_preserve_canonical_order_and_skip_blanks(self) -> None:
        apt_packages = ["libb1", "liba1", "", "libb-dev", "liba1"]  # type: ignore[list-item]
        # Empty entries are dropped; duplicates are preserved (matches apt_packages ordering).
        self.assertEqual(
            proof.runtime_packages_from_apt_packages(apt_packages),
            ["libb1", "liba1", "liba1"],
        )

    def test_runtime_packages_match_real_libjpeg_turbo_subset(self) -> None:
        apt_packages = [
            "libjpeg-turbo8",
            "libjpeg-turbo8-dev",
            "libturbojpeg",
            "libturbojpeg0-dev",
            "libjpeg-turbo-progs",
        ]
        self.assertEqual(
            proof.runtime_packages_from_apt_packages(apt_packages),
            ["libjpeg-turbo8", "libturbojpeg"],
        )


class ProofTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name)
        self.artifacts_root = self.root / "artifacts"
        self.config = original_demo_config()
        self.tests_root = FIXTURES / "original-only-tests"
        self.case_manifest = load_testcase_manifest(
            self.tests_root / "original-demo" / "testcases.yml",
            library="original-demo",
        )

    def write_cast(
        self,
        case_id: str,
        *,
        header: object | str | None = None,
        events: list[object] | None = None,
    ) -> None:
        cast_path = self.artifacts_root / "casts" / "original-demo" / f"{case_id}.cast"
        cast_path.parent.mkdir(parents=True, exist_ok=True)
        header = header if header is not None else {"version": 2, "width": 120, "height": 40}
        events = events if events is not None else [[0.1, "o", f"{case_id}\n"]]
        lines = [
            json.dumps(header) if not isinstance(header, str) else header,
            *[json.dumps(event) if not isinstance(event, str) else event for event in events],
        ]
        cast_path.write_text("\n".join(lines) + "\n")

    def write_result(
        self,
        case_id: str,
        *,
        status: object = "passed",
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

    def write_port_result(
        self,
        case_id: str,
        *,
        status: object = "passed",
        cast: bool = True,
        updates: dict[str, object] | None = None,
    ) -> None:
        cases = {case.id: case for case in self.case_manifest.testcases}
        testcase = cases[case_id]
        result_path = self.artifacts_root / "port-04-test" / "results" / "original-demo" / f"{case_id}.json"
        log_path = self.artifacts_root / "port-04-test" / "logs" / "original-demo" / f"{case_id}.log"
        cast_path = self.artifacts_root / "port-04-test" / "casts" / "original-demo" / f"{case_id}.cast"
        result_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.write_text(f"port log for {case_id}\n")
        cast_value: str | None = None
        if cast:
            cast_path.parent.mkdir(parents=True, exist_ok=True)
            cast_path.write_text(
                '{"version": 2, "width": 120, "height": 40}\n'
                f'[0.1, "o", "{case_id}\\n"]\n'
            )
            cast_value = f"port-04-test/casts/original-demo/{case_id}.cast"
        port_debs = [
            {
                "package": "demo-runtime",
                "filename": "demo-runtime_1.0_amd64.deb",
                "architecture": "amd64",
                "sha256": "a" * 64,
                "size": 10,
            }
        ]
        payload: dict[str, object] = {
            "schema_version": 2,
            "library": "original-demo",
            "mode": "port-04-test",
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
            "result_path": f"port-04-test/results/original-demo/{case_id}.json",
            "log_path": f"port-04-test/logs/original-demo/{case_id}.log",
            "cast_path": cast_value,
            "exit_code": 0 if status == "passed" else 1,
            "command": list(testcase.command),
            "apt_packages": list(self.case_manifest.apt_packages),
            "override_debs_installed": True,
            "port_repository": "safelibs/port-original-demo",
            "port_tag_ref": "refs/tags/v1.2.3",
            "port_commit": "abcdef1234567890abcdef1234567890abcdef12",
            "port_release_tag": "v1.2.3",
            "port_debs": port_debs,
            "unported_original_packages": ["demo-dev"],
            "override_installed_packages": [
                {
                    "package": "demo-runtime",
                    "version": "1.0",
                    "architecture": "amd64",
                    "filename": "demo-runtime_1.0_amd64.deb",
                }
            ],
        }
        if updates:
            payload.update(updates)
        result_path.write_text(json.dumps(payload, indent=2) + "\n")

    def write_port_library(self, *, cast: bool = True) -> None:
        for testcase in self.case_manifest.testcases:
            self.write_port_result(testcase.id, cast=cast)

    def write_library(self, *, cast: bool = True) -> None:
        for testcase in self.case_manifest.testcases:
            self.write_result(testcase.id, cast=cast)

    def build(self, **kwargs: object) -> dict[str, object]:
        return proof.build_proof(
            self.config,
            artifact_root=self.artifacts_root,
            tests_root=self.tests_root,
            **kwargs,
        )

    def test_valid_original_only_proof_generation(self) -> None:
        self.write_library()

        result = self.build(require_casts=True)

        self.assertEqual(set(result), {"proof_version", "mode", "suite", "totals", "libraries"})
        self.assertEqual(result["proof_version"], 2)
        self.assertEqual(result["mode"], "original")
        self.assertEqual(result["suite"], self.config["suite"])
        self.assertEqual(
            result["totals"],
            {
                "libraries": 1,
                "cases": 2,
                "source_cases": 1,
                "usage_cases": 1,
                "passed": 2,
                "failed": 0,
                "casts": 2,
            },
        )
        library = result["libraries"][0]
        self.assertEqual(library["library"], "original-demo")
        self.assertEqual(library["apt_packages"], ["demo-runtime", "demo-dev"])
        self.assertEqual(library["runtime_packages"], [])
        self.assertEqual(library["totals"]["cases"], 2)
        self.assertEqual(library["testcases"][0]["title"], "Source echo round trip")
        self.assertEqual(library["testcases"][0]["mode"], "original")
        self.assertEqual(library["testcases"][0]["cast_events"], 1)
        self.assertEqual(library["testcases"][0]["cast_bytes"], len("source-echo-roundtrip\n"))

    def test_valid_port_proof_generation_requires_install_status(self) -> None:
        self.write_port_library()

        result = self.build(mode="port-04-test", require_casts=True)

        self.assertEqual(result["mode"], "port-04-test")
        library = result["libraries"][0]
        self.assertEqual(library["port_repository"], "safelibs/port-original-demo")
        self.assertEqual(library["port_tag_ref"], "refs/tags/v1.2.3")
        self.assertEqual(library["port_commit"], "abcdef1234567890abcdef1234567890abcdef12")
        self.assertEqual(library["port_release_tag"], "v1.2.3")
        self.assertEqual([deb["package"] for deb in library["port_debs"]], ["demo-runtime"])
        self.assertEqual(library["unported_original_packages"], ["demo-dev"])
        testcase = library["testcases"][0]
        self.assertEqual(testcase["mode"], "port-04-test")
        self.assertEqual(testcase["result_path"], "port-04-test/results/original-demo/source-echo-roundtrip.json")
        self.assertEqual(testcase["log_path"], "port-04-test/logs/original-demo/source-echo-roundtrip.log")

        self.tempdir.cleanup()
        self.setUp()
        self.write_port_library()
        self.write_port_result("source-echo-roundtrip", updates={"override_installed_packages": []})
        with self.assertRaisesRegex(ValidatorError, "override_installed_packages"):
            self.build(mode="port-04-test")

    def test_valid_unavailable_port_proof_generation(self) -> None:
        unavailable = {
            "status": "failed",
            "exit_code": 1,
            "override_debs_installed": False,
            "port_tag_ref": None,
            "port_commit": None,
            "port_release_tag": None,
            "port_debs": [],
            "unported_original_packages": ["demo-runtime", "demo-dev"],
            "override_installed_packages": [],
            "port_unavailable_reason": "no qualifying release",
            "error": "no qualifying release",
        }
        for testcase in self.case_manifest.testcases:
            self.write_port_result(testcase.id, status="failed", cast=False, updates=unavailable)

        result = self.build(mode="port-04-test", require_casts=True)

        self.assertEqual(result["totals"]["passed"], 0)
        self.assertEqual(result["totals"]["failed"], 2)
        library = result["libraries"][0]
        self.assertEqual(library["port_debs"], [])
        self.assertEqual(library["unported_original_packages"], ["demo-runtime", "demo-dev"])
        self.assertEqual(library["port_unavailable_reason"], "no qualifying release")

        self.tempdir.cleanup()
        self.setUp()
        self.write_port_result("source-echo-roundtrip", cast=False, updates=unavailable | {"status": "passed"})
        self.write_port_result("usage-client-echo", status="failed", cast=False, updates=unavailable)
        with self.assertRaisesRegex(ValidatorError, "unavailable port results must be failed"):
            self.build(mode="port-04-test")

        self.tempdir.cleanup()
        self.setUp()
        self.write_port_result("source-echo-roundtrip", status="failed", updates=unavailable)
        self.write_port_result("usage-client-echo", status="failed", cast=False, updates=unavailable)
        with self.assertRaisesRegex(ValidatorError, "must not define cast_path"):
            self.build(mode="port-04-test")

    def test_port_proof_rejects_bad_provenance_and_paths(self) -> None:
        cases = [
            ({"override_debs_installed": False}, "must be true"),
            ({"port_release_tag": "v9.9.9"}, "port_tag_ref must equal"),
            ({"port_debs": []}, "port_debs"),
            ({"unported_original_packages": []}, "canonical apt_packages"),
            ({"result_path": "results/original-demo/source-echo-roundtrip.json"}, "result_path must equal"),
            (
                {
                    "override_installed_packages": [
                        {
                            "package": "demo-runtime",
                            "version": "1.0",
                            "architecture": "all",
                            "filename": "demo-runtime_1.0_amd64.deb",
                        }
                    ]
                },
                "align with port_debs",
            ),
        ]
        for updates, message in cases:
            with self.subTest(updates=updates):
                self.write_port_library()
                self.write_port_result("source-echo-roundtrip", updates=updates)
                with self.assertRaisesRegex(ValidatorError, message):
                    self.build(mode="port-04-test")
                self.tempdir.cleanup()
                self.setUp()

        self.write_port_library()
        self.write_port_result(
            "usage-client-echo",
            updates={
                "port_tag_ref": "refs/tags/v9.9.9",
                "port_commit": "bbbbbb1234567890abcdef1234567890abcdef12",
                "port_release_tag": "v9.9.9",
            },
        )
        with self.assertRaisesRegex(ValidatorError, "inconsistent port provenance"):
            self.build(mode="port-04-test")

    def test_result_status_must_be_passed_or_failed(self) -> None:
        for status in ("skipped", "warned", "excluded", None, "", "errored"):
            with self.subTest(status=status):
                self.write_library()
                self.write_result("source-echo-roundtrip", status=status)
                with self.assertRaisesRegex(ValidatorError, "status must be passed or failed"):
                    self.build()
                self.tempdir.cleanup()
                self.setUp()

    def test_result_schema_identity_and_override_checks_are_enforced(self) -> None:
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
            ("override_debs_installed", True, "must be false"),
        ]
        for field, value, message in mutations:
            with self.subTest(field=field):
                self.write_library()
                self.write_result("source-echo-roundtrip", updates={field: value})
                with self.assertRaisesRegex(ValidatorError, message):
                    self.build()
                self.tempdir.cleanup()
                self.setUp()

    def test_unsupported_result_fields_are_rejected_except_error(self) -> None:
        self.write_library()
        self.write_result("source-echo-roundtrip", updates={"unexpected": "value"})
        with self.assertRaisesRegex(ValidatorError, "unsupported result fields"):
            self.build()

        self.tempdir.cleanup()
        self.setUp()
        self.write_library()
        self.write_result("source-echo-roundtrip", updates={"error": "command failed"})
        self.build()

    def test_exact_result_json_set_is_enforced(self) -> None:
        self.write_library()
        extra = self.artifacts_root / "results" / "original-demo" / "extra-case.json"
        extra.write_text("{}\n")

        with self.assertRaisesRegex(ValidatorError, "unexpected extra-case"):
            self.build()

    def test_apt_package_and_testcase_metadata_mismatches_are_rejected(self) -> None:
        cases = [
            ({"apt_packages": ["demo-dev", "demo-runtime"]}, "apt_packages mismatch"),
            ({"title": "Different"}, "title mismatch"),
            ({"command": ["bash", "-c", "true"]}, "command mismatch"),
        ]
        for updates, message in cases:
            with self.subTest(updates=updates):
                self.write_library()
                self.write_result("source-echo-roundtrip", updates=updates)
                with self.assertRaisesRegex(ValidatorError, message):
                    self.build()
                self.tempdir.cleanup()
                self.setUp()

        drifted = original_demo_config()
        drifted["libraries"][0]["apt_packages"] = ["wrong-package"]  # type: ignore[index]
        self.write_library()
        with self.assertRaisesRegex(ValidatorError, "apt_packages mismatch"):
            proof.build_proof(
                drifted,
                artifact_root=self.artifacts_root,
                tests_root=self.tests_root,
            )

    def test_missing_log_and_cast_requirements_are_rejected(self) -> None:
        self.write_library()
        (self.artifacts_root / "logs" / "original-demo" / "source-echo-roundtrip.log").unlink()
        with self.assertRaisesRegex(ValidatorError, "log_path does not exist"):
            self.build()

        self.tempdir.cleanup()
        self.setUp()
        self.write_library(cast=False)
        with self.assertRaisesRegex(ValidatorError, "cast_path is required"):
            self.build(require_casts=True)

    def test_cast_validation_rejects_bad_casts(self) -> None:
        cases = [
            ({"version": 1, "width": 120, "height": 40}, None, "header version"),
            ("not json", None, "invalid cast header JSON"),
            ({"version": 2, "width": 0, "height": 40}, None, "header width"),
            (None, [[0.1, "i", "x"]], "event type"),
            (None, [[0.2, "o", "x"], [0.1, "o", "y"]], "nondecreasing"),
            (None, [[0.1, "o", {"not": "text"}]], "payload must be a string"),
            (None, [], "at least one output event"),
            (None, ["not json"], "invalid cast event JSON"),
        ]
        for header, events, message in cases:
            with self.subTest(message=message):
                self.write_library()
                kwargs: dict[str, object] = {}
                if header is not None:
                    kwargs["header"] = header
                if events is not None:
                    kwargs["events"] = events
                self.write_cast("source-echo-roundtrip", **kwargs)
                with self.assertRaisesRegex(ValidatorError, message):
                    self.build()
                self.tempdir.cleanup()
                self.setUp()

    def test_proof_validation_does_not_mutate_artifacts(self) -> None:
        self.write_library()
        result_path = self.artifacts_root / "results" / "original-demo" / "source-echo-roundtrip.json"
        log_path = self.artifacts_root / "logs" / "original-demo" / "source-echo-roundtrip.log"
        cast_path = self.artifacts_root / "casts" / "original-demo" / "source-echo-roundtrip.cast"
        before_result = result_path.read_text()
        before_log = log_path.read_text()
        before_cast = cast_path.read_text()

        self.build(require_casts=True)

        self.assertEqual(result_path.read_text(), before_result)
        self.assertEqual(log_path.read_text(), before_log)
        self.assertEqual(cast_path.read_text(), before_cast)

    def test_subset_and_threshold_checks(self) -> None:
        self.write_library()

        subset = self.build(libraries=["original-demo"])
        self.assertEqual(subset["totals"]["libraries"], 1)

        with self.assertRaisesRegex(ValidatorError, "case threshold"):
            self.build(min_cases=3)
        with self.assertRaisesRegex(ValidatorError, "source case threshold"):
            self.build(min_source_cases=2)
        with self.assertRaisesRegex(ValidatorError, "usage case threshold"):
            self.build(min_usage_cases=2)

    def test_cli_validates_output_paths_and_writes_proof(self) -> None:
        self.write_library()
        with mock.patch("tools.verify_proof_artifacts.load_manifest", return_value=self.config):
            exit_code = verify_proof_artifacts.main(
                [
                    "--config",
                    str(FIXTURES / "original-only-manifest.yml"),
                    "--tests-root",
                    str(self.tests_root),
                    "--artifact-root",
                    str(self.artifacts_root),
                    "--proof-output",
                    "proof/original-validation-proof.json",
                    "--require-casts",
                    "--min-cases",
                    "2",
                ]
            )

        self.assertEqual(exit_code, 0)
        proof_path = self.artifacts_root / "proof" / "original-validation-proof.json"
        self.assertTrue(proof_path.is_file())
        self.assertEqual(json.loads(proof_path.read_text())["proof_version"], 2)

        absolute_proof_path = self.artifacts_root / "proof" / "absolute-proof.json"
        with mock.patch("tools.verify_proof_artifacts.load_manifest", return_value=self.config):
            exit_code = verify_proof_artifacts.main(
                [
                    "--config",
                    str(FIXTURES / "original-only-manifest.yml"),
                    "--tests-root",
                    str(self.tests_root),
                    "--artifact-root",
                    str(self.artifacts_root),
                    "--proof-output",
                    str(absolute_proof_path),
                    "--min-source-cases",
                    "1",
                ]
            )
        self.assertEqual(exit_code, 0)
        self.assertTrue(absolute_proof_path.is_file())

        old_cwd = Path.cwd()
        try:
            os.chdir(self.root)
            with mock.patch("tools.verify_proof_artifacts.load_manifest", return_value=self.config):
                exit_code = verify_proof_artifacts.main(
                    [
                        "--config",
                        str(FIXTURES / "original-only-manifest.yml"),
                        "--tests-root",
                        str(self.tests_root),
                        "--artifact-root",
                        "artifacts",
                        "--proof-output",
                        "artifacts/proof/repo-relative-proof.json",
                    ]
                )
        finally:
            os.chdir(old_cwd)
        self.assertEqual(exit_code, 0)
        self.assertTrue((self.artifacts_root / "proof" / "repo-relative-proof.json").is_file())

        for output in ("../proof.json", "proof\\bad.json", "/tmp/proof.json", "proof//bad.json", "proof/./bad.json"):
            with self.subTest(output=output):
                with self.assertRaisesRegex(ValidatorError, "--proof-output"):
                    with mock.patch("tools.verify_proof_artifacts.load_manifest", return_value=self.config):
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

    def test_cli_rejects_removed_exclusion_and_compatibility_arguments(self) -> None:
        removed_args = [
            "--exclude-library",
            "--exclude_library",
            "--exclude-note",
            "--record-casts",
            "--min-total-cases",
        ]
        for argument in removed_args:
            with self.subTest(argument=argument):
                with self.assertRaises(SystemExit):
                    verify_proof_artifacts.main(
                        [
                            "--config",
                            str(FIXTURES / "original-only-manifest.yml"),
                            "--tests-root",
                            str(self.tests_root),
                            "--artifact-root",
                            str(self.artifacts_root),
                            "--proof-output",
                            "proof/proof.json",
                            argument,
                            "value",
                        ]
                    )


if __name__ == "__main__":
    unittest.main()
