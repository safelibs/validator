from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import ValidatorError
from tools import run_matrix


FIXTURES = Path(__file__).resolve().parent / "fixtures"


class RunMatrixTests(unittest.TestCase):
    def run_root(self) -> Path:
        tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(tempdir.cleanup)
        return Path(tempdir.name)

    def test_accepts_matrix_root_safe_deb_layout_and_records_safe_cast(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"

        exit_code = run_matrix.main(
            [
                "--config",
                str(FIXTURES / "demo-manifest.yml"),
                "--tests-root",
                str(FIXTURES / "demo-tests"),
                "--artifact-root",
                str(artifact_root),
                "--safe-deb-root",
                str(FIXTURES / "demo-debs"),
                "--mode",
                "both",
                "--record-casts",
            ]
        )

        self.assertEqual(exit_code, 0)
        original = json.loads((artifact_root / "results" / "demo" / "original.json").read_text())
        safe = json.loads((artifact_root / "results" / "demo" / "safe.json").read_text())

        self.assertEqual(original["status"], "passed")
        self.assertEqual(safe["status"], "passed")
        self.assertIsNone(original["cast_path"])
        self.assertEqual(safe["cast_path"], "casts/demo/safe.cast")
        self.assertTrue((artifact_root / safe["cast_path"]).is_file())
        self.assertTrue((artifact_root / safe["log_path"]).is_file())
        cast_lines = (artifact_root / safe["cast_path"]).read_text().splitlines()
        self.assertGreaterEqual(len(cast_lines), 2)
        self.assertEqual(json.loads(cast_lines[0])["version"], 2)

        original_log = (artifact_root / original["log_path"]).read_text()
        safe_log = (artifact_root / safe["log_path"]).read_text()
        self.assertIn("No safe debs mounted at /safedebs; skipping installation.", original_log)
        self.assertIn("demo-safe-marker not installed", original_log)
        self.assertIn("Installing safe debs from /safedebs", safe_log)
        self.assertIn("demo-safe-marker installed", safe_log)

    def test_rejects_single_library_leaf_passed_as_safe_deb_root(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"

        with self.assertRaisesRegex(ValidatorError, "matrix root"):
            run_matrix.main(
                [
                    "--config",
                    str(FIXTURES / "demo-manifest.yml"),
                    "--tests-root",
                    str(FIXTURES / "demo-tests"),
                    "--artifact-root",
                    str(artifact_root),
                    "--safe-deb-root",
                    str(FIXTURES / "demo-debs" / "demo"),
                    "--mode",
                    "safe",
                ]
            )

    def test_aggregate_failure_continues_before_returning_non_zero(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"

        exit_code = run_matrix.main(
            [
                "--config",
                str(FIXTURES / "demo-failure-manifest.yml"),
                "--tests-root",
                str(FIXTURES / "demo-failure-tests"),
                "--artifact-root",
                str(artifact_root),
                "--safe-deb-root",
                str(FIXTURES / "demo-failure-debs"),
                "--mode",
                "both",
                "--record-casts",
            ]
        )

        self.assertNotEqual(exit_code, 0)
        expected = {
            ("demo-fail", "original"),
            ("demo-fail", "safe"),
            ("demo-pass", "original"),
            ("demo-pass", "safe"),
        }
        actual = {(path.parent.name, path.stem) for path in (artifact_root / "results").glob("*/*.json")}
        self.assertEqual(actual, expected)

        fail_original = json.loads(
            (artifact_root / "results" / "demo-fail" / "original.json").read_text()
        )
        fail_safe = json.loads((artifact_root / "results" / "demo-fail" / "safe.json").read_text())
        pass_original = json.loads(
            (artifact_root / "results" / "demo-pass" / "original.json").read_text()
        )
        pass_safe = json.loads((artifact_root / "results" / "demo-pass" / "safe.json").read_text())

        self.assertEqual(fail_original["status"], "failed")
        self.assertEqual(fail_safe["status"], "failed")
        self.assertEqual(pass_original["status"], "passed")
        self.assertEqual(pass_safe["status"], "passed")
        self.assertTrue((artifact_root / "casts" / "demo-fail" / "safe.cast").is_file())
        self.assertTrue((artifact_root / "casts" / "demo-pass" / "safe.cast").is_file())

    def test_cleanup_library_images_removes_cached_tags(self) -> None:
        states = {
            "demo": run_matrix.LibraryState(image_tag="validator-demo-test"),
            "missing": run_matrix.LibraryState(),
        }
        with mock.patch(
            "tools.run_matrix.subprocess.run",
            return_value=subprocess.CompletedProcess(
                args=["docker", "image", "rm", "--force", "validator-demo-test"],
                returncode=0,
                stdout="Deleted: validator-demo-test\n",
                stderr="",
            ),
        ) as subprocess_run:
            errors = run_matrix.cleanup_library_images(states)

        self.assertEqual(errors, [])
        subprocess_run.assert_called_once_with(
            ["docker", "image", "rm", "--force", "validator-demo-test"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertIsNone(states["demo"].image_tag)

    def test_main_cleans_up_cached_images_after_running_matrix(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"
        manifest = {
            "archive": {"image": "ubuntu:24.04"},
            "inventory": {"verified_at": "2026-04-12T00:00:00Z"},
            "repositories": [{"name": "demo"}],
        }

        def fake_run_library_mode(*, state: run_matrix.LibraryState, **_: object) -> dict[str, object]:
            state.image_tag = "validator-demo-fake"
            return {
                "library": "demo",
                "mode": "original",
                "status": "passed",
                "started_at": "2026-04-12T00:00:00Z",
                "finished_at": "2026-04-12T00:00:01Z",
                "duration_seconds": 1.0,
                "log_path": "logs/demo/original.log",
                "cast_path": None,
            }

        with mock.patch("tools.run_matrix.load_manifest", return_value=manifest), mock.patch(
            "tools.run_matrix.select_repositories", return_value=manifest["repositories"]
        ), mock.patch(
            "tools.run_matrix.run_library_mode",
            side_effect=fake_run_library_mode,
        ), mock.patch("tools.run_matrix.cleanup_library_images", return_value=[]) as cleanup:
            exit_code = run_matrix.main(
                [
                    "--config",
                    str(FIXTURES / "demo-manifest.yml"),
                    "--tests-root",
                    str(FIXTURES / "demo-tests"),
                    "--artifact-root",
                    str(artifact_root),
                    "--mode",
                    "original",
                ]
            )

        self.assertEqual(exit_code, 0)
        cleanup.assert_called_once()
        self.assertEqual(cleanup.call_args.args[0]["demo"].image_tag, "validator-demo-fake")

    def test_main_rejects_path_traversal_library_names_before_writing_artifacts(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"
        manifest = {
            "archive": {"image": "ubuntu:24.04"},
            "inventory": {"verified_at": "2026-04-12T00:00:00Z"},
            "repositories": [{"name": "../../escape"}],
        }

        with mock.patch("tools.run_matrix.load_manifest", return_value=manifest), mock.patch(
            "tools.run_matrix.select_repositories", return_value=manifest["repositories"]
        ):
            with self.assertRaisesRegex(ValidatorError, "unsafe library name"):
                run_matrix.main(
                    [
                        "--config",
                        str(FIXTURES / "demo-manifest.yml"),
                        "--tests-root",
                        str(FIXTURES / "demo-tests"),
                        "--artifact-root",
                        str(artifact_root),
                        "--mode",
                        "original",
                    ]
                )

        self.assertFalse(artifact_root.exists())

    def test_safe_mode_builds_and_mounts_debs_from_port_root_when_safe_deb_root_is_omitted(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"
        port_root = root / "ports"
        repo_root = FIXTURES.parent
        manifest = {
            "archive": {"image": "ubuntu:24.04"},
            "inventory": {"verified_at": "2026-04-12T00:00:00Z"},
            "repositories": [{"name": "demo"}],
        }
        state = run_matrix.LibraryState()
        commands: list[list[str]] = []
        expected_output = artifact_root / "debs" / "demo"

        def fake_build_library(
            manifest_arg: dict[str, object],
            *,
            library: str,
            port_root: Path,
            workspace: Path,
            output: Path,
        ) -> None:
            self.assertIs(manifest_arg, manifest)
            self.assertEqual(library, "demo")
            self.assertEqual(port_root, root / "ports")
            self.assertEqual(workspace, artifact_root / ".workspace")
            self.assertEqual(output, expected_output)
            output.mkdir(parents=True, exist_ok=True)
            (output / "demo-safe_1.0_all.deb").write_text("fixture deb\n")

        def fake_run_logged(args: list[str], *, log_path: Path, cast_path: Path | None = None) -> int:
            log_path.parent.mkdir(parents=True, exist_ok=True)
            log_path.write_text("ran\n")
            if cast_path is not None:
                cast_path.parent.mkdir(parents=True, exist_ok=True)
                cast_path.write_text('{"version": 2}\n')
            commands.append(args)
            return 0

        with mock.patch(
            "tools.run_matrix.ensure_library_image",
            return_value="validator-demo-port-root",
        ), mock.patch(
            "tools.run_matrix.build_safe_debs.build_library",
            side_effect=fake_build_library,
        ) as build_library, mock.patch(
            "tools.run_matrix.run_logged",
            side_effect=fake_run_logged,
        ):
            result = run_matrix.run_library_mode(
                manifest=manifest,
                repo_root=repo_root,
                tests_root=FIXTURES / "demo-tests",
                artifact_root=artifact_root,
                port_root=port_root,
                safe_deb_root=None,
                record_casts=True,
                library="demo",
                mode="safe",
                state=state,
            )

        self.assertEqual(result["status"], "passed")
        self.assertEqual(result["cast_path"], "casts/demo/safe.cast")
        build_library.assert_called_once()
        self.assertEqual(state.safe_deb_dir, expected_output)
        self.assertEqual(len(commands), 1)
        self.assertEqual(commands[0][:3], ["docker", "run", "--rm"])
        mount_index = commands[0].index("--mount")
        self.assertEqual(
            commands[0][mount_index + 1],
            f"type=bind,src={expected_output.resolve()},dst=/safedebs,readonly",
        )
        self.assertIn("validator-demo-port-root", commands[0])


if __name__ == "__main__":
    unittest.main()
