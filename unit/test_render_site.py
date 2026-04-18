from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from tools import ValidatorError
from tools import proof
from tools import render_site
from tools import write_json


class RenderSiteTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name)
        self.artifacts_root = self.root / "artifacts"
        self.results_root = self.artifacts_root / "results"

    def write_result(
        self,
        *,
        library: str,
        mode: str,
        status: str,
        log_path: str,
        cast_path: str | None,
        downstream_summary_path: str | None = None,
    ) -> None:
        target = self.results_root / library / f"{mode}.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        (self.artifacts_root / log_path).parent.mkdir(parents=True, exist_ok=True)
        (self.artifacts_root / log_path).write_text(f"log for {library}/{mode}\n")
        if cast_path is not None:
            (self.artifacts_root / cast_path).parent.mkdir(parents=True, exist_ok=True)
            (self.artifacts_root / cast_path).write_text(
                '{"version": 2, "width": 120, "height": 40}\n[0.1, "o", "ran\\n"]\n'
            )
        if downstream_summary_path is None:
            downstream_summary_path = f"downstream/{library}/{mode}/summary.json"
        target.write_text(
            json.dumps(
                {
                    "library": library,
                    "mode": mode,
                    "execution_strategy": "host-harness",
                    "status": status,
                    "started_at": "2026-04-12T00:00:00Z",
                    "finished_at": "2026-04-12T00:00:01Z",
                    "duration_seconds": 1.0,
                    "log_path": log_path,
                    "cast_path": cast_path,
                    "exit_code": 0 if status == "passed" else 1,
                    "downstream_summary_path": downstream_summary_path,
                }
            )
        )

    def write_summary(self, *, library: str, mode: str, count: int = 2, status: str = "passed") -> None:
        selected = [f"{library}-{mode}-{index}" for index in range(count)]
        payload = {
            "summary_version": 1,
            "library": library,
            "mode": mode,
            "status": status,
            "report_format": "imported-log-marker",
            "expected_dependents": count,
            "selected_dependents": selected,
            "passed_dependents": selected if status == "passed" else selected[1:],
            "failed_dependents": [] if status == "passed" else selected[:1],
            "warned_dependents": [],
            "skipped_dependents": [],
            "artifacts": {
                "console_log": f"downstream/{library}/{mode}/raw/console.log",
            },
        }
        write_json(self.artifacts_root / "downstream" / library / mode / "summary.json", payload)

    def write_complete_library(self, library: str) -> None:
        self.write_summary(library=library, mode="original")
        self.write_summary(library=library, mode="safe")
        self.write_result(
            library=library,
            mode="original",
            status="passed",
            log_path=f"logs/{library}/original.log",
            cast_path=None,
        )
        self.write_result(
            library=library,
            mode="safe",
            status="passed",
            log_path=f"logs/{library}/safe.log",
            cast_path=f"casts/{library}/safe.cast",
        )

    def manifest(self, libraries: list[str]) -> dict[str, object]:
        return {
            "archive": {"image": "ubuntu:24.04"},
            "inventory": {"verified_at": "2026-04-12T00:00:00Z"},
            "repositories": [
                {
                    "name": library,
                    "github_repo": f"safelibs/port-{library}",
                    "ref": f"refs/tags/{library}/04-test",
                    "build": {"mode": "safe-debian", "artifact_globs": ["*.deb"]},
                    "validator": {
                        "sibling_repo": f"port-{library}",
                        "execution_strategy": "host-harness",
                        "imports": ["safe"],
                        "import_excludes": [],
                    },
                    "fixtures": {
                        "dependents": {"source": "copy-staged-root"},
                        "relevant_cves": {"source": "copy-staged-root"},
                    },
                }
                for library in libraries
            ],
        }

    def write_manifest(self, libraries: list[str]) -> Path:
        import yaml

        manifest_path = self.root / "manifest.yml"
        manifest_path.write_text(yaml.safe_dump(self.manifest(libraries), sort_keys=False))
        return manifest_path

    def write_proof(
        self,
        libraries: list[str],
        *,
        excluded_libraries: dict[str, str] | None = None,
    ) -> Path:
        proof_data = proof.build_proof(
            self.manifest(libraries),
            artifact_root=self.artifacts_root,
            excluded_libraries=excluded_libraries,
        )
        proof_path = self.artifacts_root / "proof" / "validator-proof.json"
        write_json(proof_path, proof_data)
        return proof_path

    def render_with_proof(
        self,
        libraries: list[str],
        *,
        excluded_libraries: dict[str, str] | None = None,
    ) -> tuple[Path, Path, Path]:
        for library in libraries:
            self.write_complete_library(library)
        manifest_path = self.write_manifest(libraries)
        proof_path = self.write_proof(libraries, excluded_libraries=excluded_libraries)
        site_root = self.root / "site"
        render_site.main(
            [
                "--results-root",
                str(self.results_root),
                "--artifacts-root",
                str(self.artifacts_root),
                "--proof-path",
                str(proof_path),
                "--output-root",
                str(site_root),
            ]
        )
        return manifest_path, proof_path, site_root

    def run_verify_site(self, *, manifest_path: Path, site_root: Path, proof_path: Path | None = None) -> subprocess.CompletedProcess[str]:
        repo_root = Path(__file__).resolve().parents[1]
        command = [
            "bash",
            str(repo_root / "scripts" / "verify-site.sh"),
            "--config",
            str(manifest_path),
            "--results-root",
            str(self.results_root),
            "--artifacts-root",
            str(self.artifacts_root),
            "--site-root",
            str(site_root),
        ]
        if proof_path is not None:
            command.extend(["--proof-path", str(proof_path)])
        return subprocess.run(
            command,
            cwd=repo_root,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_render_site_is_deterministic_and_links_to_logs_and_casts(self) -> None:
        self.write_result(
            library="demo",
            mode="safe",
            status="passed",
            log_path="logs/demo/safe.log",
            cast_path="casts/demo/safe.cast",
        )
        self.write_result(
            library="demo",
            mode="original",
            status="passed",
            log_path="logs/demo/original.log",
            cast_path=None,
        )

        first_output = self.root / "site-a"
        second_output = self.root / "site-b"
        render_site.main(
            [
                "--results-root",
                str(self.results_root),
                "--artifacts-root",
                str(self.artifacts_root),
                "--output-root",
                str(first_output),
            ]
        )
        render_site.main(
            [
                "--results-root",
                str(self.results_root),
                "--artifacts-root",
                str(self.artifacts_root),
                "--output-root",
                str(second_output),
            ]
        )

        self.assertEqual(
            (first_output / "index.html").read_text(),
            (second_output / "index.html").read_text(),
        )

        site_data = json.loads((first_output / "site-data.json").read_text())
        self.assertEqual(
            [(row["library"], row["mode"]) for row in site_data["results"]],
            [("demo", "original"), ("demo", "safe")],
        )
        self.assertEqual(site_data["results"][0]["cast_href"], None)
        self.assertEqual(site_data["results"][1]["cast_href"], "../artifacts/casts/demo/safe.cast")

        html_text = (first_output / "index.html").read_text()
        self.assertIn('data-library="demo" data-mode="original"', html_text)
        self.assertIn('data-library="demo" data-mode="safe"', html_text)
        self.assertIn("../artifacts/logs/demo/original.log", html_text)
        self.assertIn("../artifacts/casts/demo/safe.cast", html_text)

    def test_load_results_accepts_explicit_artifacts_root(self) -> None:
        separate_results_root = self.root / "results-only"
        target = separate_results_root / "demo" / "safe.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        (self.artifacts_root / "logs" / "demo").mkdir(parents=True, exist_ok=True)
        (self.artifacts_root / "logs" / "demo" / "safe.log").write_text("log\n")
        target.write_text(
            json.dumps(
                {
                    "library": "demo",
                    "mode": "safe",
                    "status": "passed",
                    "started_at": "2026-04-12T00:00:00Z",
                    "finished_at": "2026-04-12T00:00:01Z",
                    "duration_seconds": 1.0,
                    "log_path": "logs/demo/safe.log",
                    "cast_path": None,
                }
            )
        )

        results = render_site.load_results(
            separate_results_root,
            artifacts_root=self.artifacts_root,
        )

        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["library"], "demo")

    def test_render_site_rejects_missing_required_result_field_even_with_extra_fields(self) -> None:
        target = self.results_root / "demo" / "safe.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        (self.artifacts_root / "logs" / "demo").mkdir(parents=True, exist_ok=True)
        (self.artifacts_root / "logs" / "demo" / "safe.log").write_text("log\n")
        target.write_text(
            json.dumps(
                {
                    "library": "demo",
                    "mode": "safe",
                    "status": "passed",
                    "started_at": "2026-04-12T00:00:00Z",
                    "finished_at": "2026-04-12T00:00:01Z",
                    "log_path": "logs/demo/safe.log",
                    "cast_path": None,
                    "exit_code": 0,
                }
            )
        )

        with self.assertRaisesRegex(ValidatorError, "result schema mismatch"):
            render_site.main(
                [
                    "--results-root",
                    str(self.results_root),
                    "--artifacts-root",
                    str(self.artifacts_root),
                    "--output-root",
                    str(self.root / "site"),
                ]
            )

    def test_render_site_rejects_traversal_artifact_paths(self) -> None:
        target = self.results_root / "demo" / "safe.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            json.dumps(
                {
                    "library": "demo",
                    "mode": "safe",
                    "status": "passed",
                    "started_at": "2026-04-12T00:00:00Z",
                    "finished_at": "2026-04-12T00:00:01Z",
                    "duration_seconds": 1.0,
                    "log_path": "../../../etc/hosts",
                    "cast_path": None,
                }
            )
        )

        with self.assertRaisesRegex(ValidatorError, "artifact-root-relative|artifact root"):
            render_site.main(
                [
                    "--results-root",
                    str(self.results_root),
                    "--artifacts-root",
                    str(self.artifacts_root),
                    "--output-root",
                    str(self.root / "site"),
                ]
            )

    def test_verify_site_rejects_traversal_paths(self) -> None:
        repo_root = Path(__file__).resolve().parents[1]
        manifest_path = self.write_manifest(["demo"])
        self.write_summary(library="demo", mode="original")
        self.write_summary(library="demo", mode="safe")
        self.write_result(
            library="demo",
            mode="original",
            status="passed",
            log_path="logs/demo/original.log",
            cast_path=None,
        )

        target = self.results_root / "demo" / "safe.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            json.dumps(
                {
                    "library": "demo",
                    "mode": "safe",
                    "status": "passed",
                    "started_at": "2026-04-12T00:00:00Z",
                    "finished_at": "2026-04-12T00:00:01Z",
                    "duration_seconds": 1.0,
                    "execution_strategy": "host-harness",
                    "log_path": "../../../etc/hosts",
                    "cast_path": None,
                    "exit_code": 0,
                    "downstream_summary_path": "downstream/demo/safe/summary.json",
                }
            )
        )
        proof_path = self.artifacts_root / "proof" / "validator-proof.json"
        write_json(
            proof_path,
            {
                "proof_version": 1,
                "included_libraries": ["demo"],
                "excluded_libraries": [],
                "totals": {},
                "libraries": [],
            },
        )

        site_root = self.root / "site"
        site_root.mkdir(parents=True, exist_ok=True)
        (site_root / "site-data.json").write_text(
            json.dumps(
                {
                    "results": [
                        {
                            "library": "demo",
                            "mode": "safe",
                            "status": "passed",
                            "log_path": "../../../etc/hosts",
                            "cast_path": None,
                            "log_href": "../../../etc/hosts",
                            "cast_href": None,
                        }
                    ],
                    "proof": {
                        "proof_version": 1,
                        "included_libraries": ["demo"],
                        "excluded_libraries": [],
                        "totals": {},
                        "libraries": [],
                    },
                }
            )
        )
        (site_root / "index.html").write_text('<tr data-library="demo" data-mode="safe"></tr>\n')

        completed = subprocess.run(
            [
                "bash",
                str(repo_root / "scripts" / "verify-site.sh"),
                "--config",
                str(manifest_path),
                "--results-root",
                str(self.results_root),
                "--artifacts-root",
                str(self.artifacts_root),
                "--proof-path",
                str(proof_path),
                "--site-root",
                str(site_root),
            ],
            cwd=repo_root,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("artifact-root-relative", completed.stderr + completed.stdout)

    def test_verify_site_accepts_explicit_artifacts_root(self) -> None:
        self.write_complete_library("demo")
        manifest_path = self.write_manifest(["demo"])
        proof_path = self.write_proof(["demo"])

        site_root = self.root / "site"
        render_site.main(
            [
                "--results-root",
                str(self.results_root),
                "--artifacts-root",
                str(self.artifacts_root),
                "--proof-path",
                str(proof_path),
                "--output-root",
                str(site_root),
            ]
        )

        completed = self.run_verify_site(
            manifest_path=manifest_path,
            proof_path=proof_path,
            site_root=site_root,
        )

        self.assertEqual(completed.returncode, 0, completed.stderr + completed.stdout)

    def test_render_site_includes_proof_data_and_hosted_exclusions(self) -> None:
        _, proof_path, site_root = self.render_with_proof(
            ["alpha", "beta"],
            excluded_libraries={"beta": "hosted beta exclusion"},
        )

        site_data = json.loads((site_root / "site-data.json").read_text())
        self.assertEqual(set(site_data), {"results", "proof"})
        self.assertEqual(
            [(row["library"], row["mode"]) for row in site_data["results"]],
            [("alpha", "original"), ("alpha", "safe")],
        )
        self.assertEqual(site_data["proof"]["included_libraries"], ["alpha"])
        self.assertEqual(
            site_data["proof"]["excluded_libraries"],
            [{"library": "beta", "note": "hosted beta exclusion"}],
        )
        safe_entry = site_data["proof"]["libraries"][0]["safe"]
        self.assertEqual(safe_entry["cast_href"], "../artifacts/casts/alpha/safe.cast")
        self.assertTrue((site_root / safe_entry["cast_href"]).resolve().is_file())

        html_text = (site_root / "index.html").read_text()
        self.assertIn('data-proof-library="alpha"', html_text)
        self.assertIn('data-proof-excluded-library="beta"', html_text)
        self.assertIn("hosted beta exclusion", html_text)
        self.assertNotIn('data-library="beta"', html_text)
        self.assertIn("../artifacts/casts/alpha/safe.cast", html_text)
        self.assertTrue(proof_path.is_file())

    def test_verify_site_rejects_proof_path_traversal(self) -> None:
        manifest_path, _, site_root = self.render_with_proof(["alpha"])
        outside_proof = self.root / "outside-proof.json"
        outside_proof.write_text("{}\n")

        completed = self.run_verify_site(
            manifest_path=manifest_path,
            proof_path=outside_proof,
            site_root=site_root,
        )

        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("proof path must resolve inside", completed.stderr + completed.stdout)

    def test_verify_site_rejects_malformed_or_duplicate_excluded_entries(self) -> None:
        manifest_path, proof_path, site_root = self.render_with_proof(
            ["alpha", "beta"],
            excluded_libraries={"beta": "hosted beta exclusion"},
        )

        original = json.loads(proof_path.read_text())
        for excluded_libraries, message in (
            ([{"library": "beta"}], "malformed excluded library entry"),
            (
                [
                    {"library": "beta", "note": "one"},
                    {"library": "beta", "note": "two"},
                ],
                "duplicate excluded library entry",
            ),
        ):
            with self.subTest(message=message):
                proof_payload = dict(original)
                proof_payload["excluded_libraries"] = excluded_libraries
                write_json(proof_path, proof_payload)

                completed = self.run_verify_site(
                    manifest_path=manifest_path,
                    proof_path=proof_path,
                    site_root=site_root,
                )

                self.assertNotEqual(completed.returncode, 0)
                self.assertIn(message, completed.stderr + completed.stdout)
        write_json(proof_path, original)

    def test_verify_site_rejects_missing_or_altered_proof_rows(self) -> None:
        manifest_path, proof_path, site_root = self.render_with_proof(["alpha"])
        site_data_path = site_root / "site-data.json"
        original_site_data = json.loads(site_data_path.read_text())

        for mutate, message in (
            (
                lambda data: data["proof"].update({"libraries": []}),
                "site-data.json proof does not match",
            ),
            (
                lambda data: data["proof"]["libraries"][0]["safe"].update({"cast_events": 999}),
                "site-data.json proof does not match",
            ),
        ):
            with self.subTest(message=message):
                site_data = json.loads(json.dumps(original_site_data))
                mutate(site_data)
                write_json(site_data_path, site_data)

                completed = self.run_verify_site(
                    manifest_path=manifest_path,
                    proof_path=proof_path,
                    site_root=site_root,
                )

                self.assertNotEqual(completed.returncode, 0)
                self.assertIn(message, completed.stderr + completed.stdout)
        write_json(site_data_path, original_site_data)

    def test_verify_site_rejects_changed_result_hrefs(self) -> None:
        manifest_path, proof_path, site_root = self.render_with_proof(["alpha"])
        site_data_path = site_root / "site-data.json"
        original_site_data = json.loads(site_data_path.read_text())

        for row_index, field_name in ((0, "log_href"), (1, "cast_href")):
            with self.subTest(field_name=field_name):
                site_data = json.loads(json.dumps(original_site_data))
                site_data["results"][row_index][field_name] = "../artifacts/logs/alpha/wrong.log"
                write_json(site_data_path, site_data)

                completed = self.run_verify_site(
                    manifest_path=manifest_path,
                    proof_path=proof_path,
                    site_root=site_root,
                )

                self.assertNotEqual(completed.returncode, 0)
                self.assertIn("site-data.json results do not match", completed.stderr + completed.stdout)
        write_json(site_data_path, original_site_data)

    def test_verify_site_rejects_stale_excluded_result_rows(self) -> None:
        manifest_path, proof_path, site_root = self.render_with_proof(
            ["alpha", "beta"],
            excluded_libraries={"beta": "hosted beta exclusion"},
        )
        site_data_path = site_root / "site-data.json"
        site_data = json.loads(site_data_path.read_text())
        site_data["results"].append(
            {
                "library": "beta",
                "mode": "safe",
                "status": "passed",
                "log_path": "logs/beta/safe.log",
                "cast_path": "casts/beta/safe.cast",
                "log_href": "../artifacts/logs/beta/safe.log",
                "cast_href": "../artifacts/casts/beta/safe.cast",
            }
        )
        write_json(site_data_path, site_data)

        completed = self.run_verify_site(
            manifest_path=manifest_path,
            proof_path=proof_path,
            site_root=site_root,
        )

        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("site-data.json results do not match", completed.stderr + completed.stdout)


if __name__ == "__main__":
    unittest.main()
