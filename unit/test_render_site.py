from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from tools import ValidatorError
from tools import render_site


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
    ) -> None:
        target = self.results_root / library / f"{mode}.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        (self.artifacts_root / log_path).parent.mkdir(parents=True, exist_ok=True)
        (self.artifacts_root / log_path).write_text(f"log for {library}/{mode}\n")
        if cast_path is not None:
            (self.artifacts_root / cast_path).parent.mkdir(parents=True, exist_ok=True)
            (self.artifacts_root / cast_path).write_text('{"version": 2}\n')
        target.write_text(
            json.dumps(
                {
                    "library": library,
                    "mode": mode,
                    "status": status,
                    "started_at": "2026-04-12T00:00:00Z",
                    "finished_at": "2026-04-12T00:00:01Z",
                    "duration_seconds": 1.0,
                    "log_path": log_path,
                    "cast_path": cast_path,
                }
            )
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
        manifest_path = self.root / "manifest.yml"
        manifest_path.write_text("repositories:\n  - name: demo\n")

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
                    ]
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


if __name__ == "__main__":
    unittest.main()
