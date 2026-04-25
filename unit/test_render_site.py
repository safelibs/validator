from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from tools import select_libraries, write_json
from tools import proof
from tools import render_site
from tools.inventory import load_manifest
from tools.testcases import load_manifests


class RenderSiteTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name)
        self.repo_root = Path(__file__).resolve().parents[1]
        self.config_path = self.repo_root / "repositories.yml"
        self.tests_root = self.repo_root / "tests"
        self.artifacts_root = self.root / "artifacts"
        self.site_root = self.root / "site"
        self.manifest = load_manifest(self.config_path)

    def load_selected_testcase_manifests(self, libraries: list[str]):
        selected = dict(self.manifest)
        selected["libraries"] = select_libraries(self.manifest, libraries)
        return load_manifests(selected, tests_root=self.tests_root)

    def write_library_artifacts(
        self,
        library: str,
        *,
        failed_case: str | None = None,
        casts: bool = True,
    ) -> None:
        testcase_manifest = self.load_selected_testcase_manifests([library])[library]
        for index, testcase in enumerate(testcase_manifest.testcases, start=1):
            status = "failed" if testcase.id == failed_case else "passed"
            log_path = self.artifacts_root / "logs" / library / f"{testcase.id}.log"
            result_path = self.artifacts_root / "results" / library / f"{testcase.id}.json"
            cast_path = self.artifacts_root / "casts" / library / f"{testcase.id}.cast"
            log_path.parent.mkdir(parents=True, exist_ok=True)
            result_path.parent.mkdir(parents=True, exist_ok=True)
            log_path.write_text(f"log for {library}/{testcase.id}\n")
            cast_value: str | None = None
            if casts:
                cast_path.parent.mkdir(parents=True, exist_ok=True)
                cast_path.write_text(
                    '{"version": 2, "width": 120, "height": 40}\n'
                    f'[{index / 10:.1f}, "o", "{library} {testcase.id}\\n"]\n'
                )
                cast_value = f"casts/{library}/{testcase.id}.cast"
            payload: dict[str, object] = {
                "schema_version": 2,
                "library": library,
                "mode": "original",
                "testcase_id": testcase.id,
                "title": testcase.title,
                "description": testcase.description,
                "kind": testcase.kind,
                "client_application": testcase.client_application,
                "tags": list(testcase.tags),
                "requires": list(testcase.requires),
                "status": status,
                "started_at": "2026-04-19T00:00:00Z",
                "finished_at": "2026-04-19T00:00:01Z",
                "duration_seconds": float(index),
                "result_path": f"results/{library}/{testcase.id}.json",
                "log_path": f"logs/{library}/{testcase.id}.log",
                "cast_path": cast_value,
                "exit_code": 0 if status == "passed" else 1,
                "command": list(testcase.command),
                "apt_packages": list(testcase_manifest.apt_packages),
                "override_debs_installed": False,
            }
            if status == "failed":
                payload["error"] = "synthetic failure"
            write_json(result_path, payload)

    def write_port_library_artifacts(self, library: str, *, casts: bool = True) -> None:
        testcase_manifest = self.load_selected_testcase_manifests([library])[library]
        first_package = testcase_manifest.apt_packages[0]
        port_debs = [
            {
                "package": first_package,
                "filename": f"{first_package}_1.0_amd64.deb",
                "architecture": "amd64",
                "sha256": "a" * 64,
                "size": 10,
            }
        ]
        unported = list(testcase_manifest.apt_packages[1:])
        for index, testcase in enumerate(testcase_manifest.testcases, start=1):
            log_path = self.artifacts_root / "port-04-test" / "logs" / library / f"{testcase.id}.log"
            result_path = self.artifacts_root / "port-04-test" / "results" / library / f"{testcase.id}.json"
            cast_path = self.artifacts_root / "port-04-test" / "casts" / library / f"{testcase.id}.cast"
            log_path.parent.mkdir(parents=True, exist_ok=True)
            result_path.parent.mkdir(parents=True, exist_ok=True)
            log_path.write_text(f"port log for {library}/{testcase.id}\n")
            cast_value: str | None = None
            if casts:
                cast_path.parent.mkdir(parents=True, exist_ok=True)
                cast_path.write_text(
                    '{"version": 2, "width": 120, "height": 40}\n'
                    f'[{index / 10:.1f}, "o", "port {library} {testcase.id}\\n"]\n'
                )
                cast_value = f"port-04-test/casts/{library}/{testcase.id}.cast"
            payload: dict[str, object] = {
                "schema_version": 2,
                "library": library,
                "mode": "port-04-test",
                "testcase_id": testcase.id,
                "title": testcase.title,
                "description": testcase.description,
                "kind": testcase.kind,
                "client_application": testcase.client_application,
                "tags": list(testcase.tags),
                "requires": list(testcase.requires),
                "status": "passed",
                "started_at": "2026-04-19T00:00:00Z",
                "finished_at": "2026-04-19T00:00:01Z",
                "duration_seconds": float(index),
                "result_path": f"port-04-test/results/{library}/{testcase.id}.json",
                "log_path": f"port-04-test/logs/{library}/{testcase.id}.log",
                "cast_path": cast_value,
                "exit_code": 0,
                "command": list(testcase.command),
                "apt_packages": list(testcase_manifest.apt_packages),
                "override_debs_installed": True,
                "port_repository": f"safelibs/port-{library}",
                "port_tag_ref": f"refs/tags/{library}/04-test",
                "port_commit": "abcdef1234567890abcdef1234567890abcdef12",
                "port_release_tag": "build-abcdef123456",
                "port_debs": port_debs,
                "unported_original_packages": unported,
                "override_installed_packages": [
                    {
                        "package": first_package,
                        "version": "1.0",
                        "architecture": "amd64",
                        "filename": f"{first_package}_1.0_amd64.deb",
                    }
                ],
            }
            write_json(result_path, payload)

    def write_proof(self, libraries: list[str], *, require_casts: bool = True) -> Path:
        proof_data = proof.build_proof(
            self.manifest,
            artifact_root=self.artifacts_root,
            tests_root=self.tests_root,
            libraries=libraries,
            require_casts=require_casts,
        )
        proof_path = self.artifacts_root / "proof" / "original-validation-proof.json"
        write_json(proof_path, proof_data)
        return proof_path

    def write_port_proof(self, libraries: list[str], *, require_casts: bool = True) -> Path:
        proof_data = proof.build_proof(
            self.manifest,
            artifact_root=self.artifacts_root,
            tests_root=self.tests_root,
            mode="port-04-test",
            libraries=libraries,
            require_casts=require_casts,
        )
        proof_path = self.artifacts_root / "proof" / "port-04-test-validation-proof.json"
        write_json(proof_path, proof_data)
        return proof_path

    def render(self, proof_path: Path) -> None:
        render_site.main(
            [
                "--config",
                str(self.config_path),
                "--tests-root",
                str(self.tests_root),
                "--artifact-root",
                str(self.artifacts_root),
                "--proof-path",
                str(proof_path),
                "--output-root",
                str(self.site_root),
            ]
        )

    def run_verify_site(self, proof_path: Path, *extra_args: str) -> subprocess.CompletedProcess[str]:
        command = [
            "bash",
            str(self.repo_root / "scripts" / "verify-site.sh"),
            "--config",
            str(self.config_path),
            "--tests-root",
            str(self.tests_root),
            "--artifacts-root",
            str(self.artifacts_root),
            "--proof-path",
            str(proof_path),
            "--site-root",
            str(self.site_root),
            *extra_args,
        ]
        return subprocess.run(
            command,
            cwd=self.repo_root,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_render_site_derives_data_from_proof_and_copies_evidence(self) -> None:
        self.write_library_artifacts("cjson")
        proof_path = self.write_proof(["cjson"])
        self.render(proof_path)

        site_data = json.loads((self.site_root / "site-data.json").read_text())
        self.assertEqual(list(site_data), ["schema_version", "proofs", "testcases"])
        self.assertEqual(site_data["schema_version"], 2)
        expected_site_data = render_site.build_site_data(
            json.loads(proof_path.read_text()),
            artifact_root=self.artifacts_root,
            output_root=self.site_root,
            copy_evidence=False,
        )
        self.assertEqual(site_data, expected_site_data)

        first_row = site_data["testcases"][0]
        self.assertEqual(
            set(first_row),
            {
                "library",
                "testcase_id",
                "mode",
                "title",
                "description",
                "kind",
                "client_application",
                "tags",
                "status",
                "duration_seconds",
                "result_path",
                "log_path",
                "cast_path",
                "log_href",
                "cast_href",
            },
        )
        copied_log = self.site_root / first_row["log_href"]
        copied_cast = self.site_root / first_row["cast_href"]
        self.assertEqual(first_row["library"], "cjson")
        self.assertTrue(all(row["library"] == "cjson" for row in site_data["testcases"]))
        self.assertEqual(copied_log.read_bytes(), (self.artifacts_root / first_row["log_path"]).read_bytes())
        self.assertEqual(copied_cast.read_bytes(), (self.artifacts_root / first_row["cast_path"]).read_bytes())
        self.assertTrue((self.site_root / "assets" / "player.js").is_file())
        self.assertTrue((self.site_root / "assets" / "site.css").is_file())
        self.assertTrue((self.site_root / "library" / "cjson.html").is_file())

        html_text = (self.site_root / "index.html").read_text()
        self.assertIn("Library Validation Matrix", html_text)
        self.assertIn('rel="icon" href="data:,"', html_text)
        self.assertIn('data-library="cjson"', html_text)
        self.assertIn('data-mode="original"', html_text)
        self.assertIn('data-player-cast="evidence/original/casts/cjson/', html_text)
        self.assertIn('id="search-input"', html_text)
        self.assertIn('id="mode-filter"', html_text)
        self.assertIn("js-player-pause", html_text)
        self.assertNotIn('data-library="None"', html_text)
        self.assertNotIn("None /", html_text)
        self.assertNotIn("Safe", html_text)
        self.assertNotIn("safe workload", html_text.lower())

    def test_render_site_with_original_and_port_proofs_uses_mode_evidence_hrefs(self) -> None:
        self.write_library_artifacts("cjson")
        self.write_port_library_artifacts("cjson")
        original_proof = self.write_proof(["cjson"])
        port_proof = self.write_port_proof(["cjson"])

        render_site.main(
            [
                "--config",
                str(self.config_path),
                "--tests-root",
                str(self.tests_root),
                "--artifact-root",
                str(self.artifacts_root),
                "--proof-path",
                str(original_proof),
                "--proof-path",
                str(port_proof),
                "--output-root",
                str(self.site_root),
            ]
        )

        site_data = json.loads((self.site_root / "site-data.json").read_text())
        self.assertEqual(site_data["schema_version"], 2)
        self.assertEqual([proof["mode"] for proof in site_data["proofs"]], ["original", "port-04-test"])
        modes = {row["mode"] for row in site_data["testcases"]}
        self.assertEqual(modes, {"original", "port-04-test"})
        first_original = next(row for row in site_data["testcases"] if row["mode"] == "original")
        first_port = next(row for row in site_data["testcases"] if row["mode"] == "port-04-test")
        self.assertIn("evidence/original/logs/cjson/", first_original["log_href"])
        self.assertIn("evidence/port-04-test/logs/cjson/", first_port["log_href"])
        self.assertNotEqual(first_original["cast_href"], first_port["cast_href"])
        html_text = (self.site_root / "index.html").read_text()
        self.assertIn('data-mode="original"', html_text)
        self.assertIn('data-mode="port-04-test"', html_text)
        self.assertIn("<span>Tests</span>", html_text)
        self.assertIn("<span>Port tests passing</span>", html_text)
        self.assertIn("<strong>35 / 35</strong>", html_text)

        completed = subprocess.run(
            [
                "bash",
                str(self.repo_root / "scripts" / "verify-site.sh"),
                "--config",
                str(self.config_path),
                "--tests-root",
                str(self.tests_root),
                "--artifacts-root",
                str(self.artifacts_root),
                "--proof-path",
                str(original_proof),
                "--proof-path",
                str(port_proof),
                "--site-root",
                str(self.site_root),
                "--library",
                "cjson",
            ],
            cwd=self.repo_root,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr + completed.stdout)

    def test_render_site_is_deterministic(self) -> None:
        self.write_library_artifacts("cjson")
        proof_path = self.write_proof(["cjson"])
        first_output = self.root / "site-a"
        second_output = self.root / "site-b"
        for output in (first_output, second_output):
            render_site.main(
                [
                    "--config",
                    str(self.config_path),
                    "--tests-root",
                    str(self.tests_root),
                    "--artifact-root",
                    str(self.artifacts_root),
                    "--proof-path",
                    str(proof_path),
                    "--output-root",
                    str(output),
                ]
            )

        self.assertEqual((first_output / "site-data.json").read_text(), (second_output / "site-data.json").read_text())
        self.assertEqual((first_output / "index.html").read_text(), (second_output / "index.html").read_text())
        self.assertEqual((first_output / "assets" / "player.js").read_text(), (second_output / "assets" / "player.js").read_text())

    def test_render_site_rejects_results_root_argument(self) -> None:
        with self.assertRaises(SystemExit):
            render_site.main(
                [
                    "--results-root",
                    str(self.artifacts_root / "results"),
                    "--config",
                    str(self.config_path),
                    "--tests-root",
                    str(self.tests_root),
                    "--artifact-root",
                    str(self.artifacts_root),
                    "--proof-path",
                    str(self.artifacts_root / "proof" / "missing.json"),
                    "--output-root",
                    str(self.site_root),
                ]
            )

    def test_render_page_escapes_html_and_keeps_player_wiring(self) -> None:
        site_data = {
            "schema_version": 2,
            "proofs": [{
                "proof_version": 2,
                "mode": "original",
                "totals": {
                    "libraries": 1,
                    "cases": 1,
                    "source_cases": 1,
                    "usage_cases": 0,
                    "passed": 1,
                    "failed": 0,
                    "casts": 1,
                },
                "libraries": [
                    {
                        "library": "demo",
                        "totals": {
                            "cases": 1,
                            "source_cases": 1,
                            "usage_cases": 0,
                            "passed": 1,
                            "failed": 0,
                            "casts": 1,
                        },
                        "testcases": [],
                    }
                ],
            }],
            "testcases": [
                {
                    "library": "demo",
                    "testcase_id": "source-demo-case",
                    "mode": "original",
                    "title": "<script>alert(1)</script>",
                    "description": "Checks <xml> output & escaping.",
                    "kind": "source",
                    "client_application": None,
                    "tags": ["api"],
                    "status": "passed",
                    "duration_seconds": 1.0,
                    "result_path": "results/demo/source-demo-case.json",
                    "log_path": "logs/demo/source-demo-case.log",
                    "cast_path": "casts/demo/source-demo-case.cast",
                    "log_href": "evidence/original/logs/demo/source-demo-case.log",
                    "cast_href": "evidence/original/casts/demo/source-demo-case.cast",
                }
            ],
        }

        html_text = render_site.render_page(site_data)

        self.assertIn("&lt;script&gt;alert(1)&lt;/script&gt;", html_text)
        self.assertNotIn("<script>alert(1)</script>", html_text)
        self.assertIn("data-mode=\"original\"", html_text)
        self.assertIn("data-player-cast=\"evidence/original/casts/demo/source-demo-case.cast\"", html_text)
        self.assertIn("js-player-restart", html_text)
        self.assertIn("js-player-scrub", html_text)

    def test_verify_site_accepts_proof_site_and_optional_matching_library_selection(self) -> None:
        self.write_library_artifacts("cjson")
        proof_path = self.write_proof(["cjson"])
        self.render(proof_path)

        completed = self.run_verify_site(proof_path)
        self.assertEqual(completed.returncode, 0, completed.stderr + completed.stdout)

        completed = self.run_verify_site(proof_path, "--library", "cjson")
        self.assertEqual(completed.returncode, 0, completed.stderr + completed.stdout)

    def test_verify_site_keeps_failed_rows_visible(self) -> None:
        self.write_library_artifacts("cjson", failed_case="parse-print-roundtrip")
        proof_path = self.write_proof(["cjson"])
        self.render(proof_path)

        html_text = (self.site_root / "index.html").read_text()
        self.assertIn('data-status="failed"', html_text)
        self.assertIn("Failed", html_text)
        completed = self.run_verify_site(proof_path)
        self.assertEqual(completed.returncode, 0, completed.stderr + completed.stdout)

    def test_verify_site_rejects_stale_site_data_and_copied_evidence(self) -> None:
        self.write_library_artifacts("cjson")
        proof_path = self.write_proof(["cjson"])
        self.render(proof_path)
        site_data_path = self.site_root / "site-data.json"
        original_site_data = json.loads(site_data_path.read_text())

        altered = json.loads(json.dumps(original_site_data))
        altered["testcases"][0]["status"] = "failed"
        write_json(site_data_path, altered)
        completed = self.run_verify_site(proof_path)
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("site-data.json does not match", completed.stderr + completed.stdout)

        write_json(site_data_path, original_site_data)
        first_row = original_site_data["testcases"][0]
        (self.site_root / first_row["log_href"]).write_text("stale log\n")
        completed = self.run_verify_site(proof_path)
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("copied log evidence does not match", completed.stderr + completed.stdout)

    def test_verify_site_rejects_final_safe_language_in_html(self) -> None:
        self.write_library_artifacts("cjson")
        proof_path = self.write_proof(["cjson"])

        for phrase in ("Safe validation", "safe validation", "unsafe validation", "safe-workload validation"):
            self.render(proof_path)
            index_path = self.site_root / "index.html"
            index_path.write_text(index_path.read_text().replace("</main>", f"<p>{phrase}</p></main>", 1))
            completed = self.run_verify_site(proof_path)
            self.assertNotEqual(completed.returncode, 0, phrase)
            self.assertIn("safe/unsafe language", completed.stderr + completed.stdout)

    def test_verify_site_rejects_missing_html_rows_and_bad_library_selection(self) -> None:
        self.write_library_artifacts("cjson")
        proof_path = self.write_proof(["cjson"])
        self.render(proof_path)

        index_path = self.site_root / "index.html"
        index_path.write_text(index_path.read_text().replace('data-player-cast="', 'data-player-cast-missing="', 1))
        completed = self.run_verify_site(proof_path)
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("missing testcase HTML row", completed.stderr + completed.stdout)

        self.render(proof_path)
        completed = self.run_verify_site(proof_path, "--library", "giflib")
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("must exactly match proof libraries", completed.stderr + completed.stdout)

        completed = self.run_verify_site(proof_path, "--library", "cjson", "--library", "cjson")
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("--library must not contain duplicates", completed.stderr + completed.stdout)

    def test_verify_site_rejects_removed_compatibility_arguments(self) -> None:
        self.write_library_artifacts("cjson")
        proof_path = self.write_proof(["cjson"])
        self.render(proof_path)

        completed = subprocess.run(
            [
                "bash",
                str(self.repo_root / "scripts" / "verify-site.sh"),
                "--config",
                str(self.config_path),
                "--tests-root",
                str(self.tests_root),
                "--artifacts-root",
                str(self.artifacts_root),
                "--proof-path",
                str(proof_path),
                "--site-root",
                str(self.site_root),
                "--results-root",
                str(self.artifacts_root / "results"),
            ],
            cwd=self.repo_root,
            capture_output=True,
            text=True,
            check=False,
        )

        self.assertNotEqual(completed.returncode, 0)
        self.assertIn("unexpected argument", completed.stderr + completed.stdout)


if __name__ == "__main__":
    unittest.main()
