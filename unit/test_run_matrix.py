from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import ValidatorError
from tools.host_harness import write_summary
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
        self.assertEqual(original["execution_strategy"], "container-image")
        self.assertEqual(safe["execution_strategy"], "container-image")
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

    def test_library_state_legacy_image_tag_property_maps_to_shared_variant(self) -> None:
        state = run_matrix.LibraryState(image_tags={"safe": "validator-demo-safe"})

        self.assertIsNone(state.image_tag)

        state.image_tag = "validator-demo-shared"
        self.assertEqual(state.image_tags["shared"], "validator-demo-shared")
        self.assertEqual(state.image_tag, "validator-demo-shared")

        state.image_tag = None
        self.assertNotIn("shared", state.image_tags)
        self.assertIsNone(state.image_tag)

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
        self.assertEqual(result["execution_strategy"], "container-image")
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

    def test_safe_mode_reuses_shared_image_variant_for_libxml(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"
        repo_root = Path(__file__).resolve().parents[1]
        manifest = {
            "archive": {"image": "ubuntu:24.04"},
            "inventory": {"verified_at": "2026-04-12T00:00:00Z"},
            "repositories": [{"name": "libxml"}],
        }

        with mock.patch(
            "tools.run_matrix.ensure_library_image",
            return_value="validator-libxml-shared",
        ) as ensure_image, mock.patch(
            "tools.run_matrix.ensure_safe_deb_dir",
            return_value=root / "debs" / "libxml",
        ), mock.patch(
            "tools.run_matrix.run_logged",
            return_value=0,
        ):
            result = run_matrix.run_library_mode(
                manifest=manifest,
                repo_root=repo_root,
                tests_root=repo_root / "tests",
                artifact_root=artifact_root,
                port_root=None,
                safe_deb_root=root / "safe-debs",
                record_casts=False,
                library="libxml",
                mode="safe",
                state=run_matrix.LibraryState(),
            )

        self.assertEqual(result["status"], "passed")
        self.assertEqual(result["execution_strategy"], "container-image")
        self.assertEqual(ensure_image.call_args.kwargs["variant"], "shared")
        self.assertNotIn("build_args", ensure_image.call_args.kwargs)

    def test_host_harness_strategy_materializes_scratch_repo_and_propagates_summary(self) -> None:
        root = self.run_root()
        artifact_root = root / "artifacts"
        fixture_root = FIXTURES / "demo-host-harness-tests" / "demo-host"
        real_run_logged = run_matrix.run_logged
        docker_builds: list[list[str]] = []

        def fake_run_logged(
            args: list[str],
            *,
            log_path: Path,
            cast_path: Path | None = None,
            cwd: Path | None = None,
            env: dict[str, str] | None = None,
        ) -> int:
            if args[:2] == ["docker", "build"]:
                docker_builds.append(args)
                dockerfile = Path(args[args.index("--file") + 1])
                context_root = Path(args[-1])
                self.assertTrue(dockerfile.is_file())
                self.assertIn("VALIDATOR_BASELINE_FIXTURE=demo-host-baseline", dockerfile.read_text())
                self.assertTrue((context_root / "_shared" / "install_safe_debs.sh").is_file())
                self.assertTrue((context_root / "demo-host" / "host-run.sh").is_file())
                log_path.parent.mkdir(parents=True, exist_ok=True)
                with log_path.open("a", encoding="utf-8") as handle:
                    handle.write("$ stub docker build\n")
                return 0
            return real_run_logged(
                args,
                log_path=log_path,
                cast_path=cast_path,
                cwd=cwd,
                env=env,
            )

        with mock.patch("tools.run_matrix.run_logged", side_effect=fake_run_logged), mock.patch(
            "tools.run_matrix.cleanup_library_images",
            return_value=[],
        ):
            exit_code = run_matrix.main(
                [
                    "--config",
                    str(FIXTURES / "demo-host-harness-manifest.yml"),
                    "--tests-root",
                    str(FIXTURES / "demo-host-harness-tests"),
                    "--artifact-root",
                    str(artifact_root),
                    "--safe-deb-root",
                    str(FIXTURES / "demo-host-harness-debs"),
                    "--mode",
                    "both",
                    "--record-casts",
                ]
            )

        self.assertEqual(exit_code, 0)
        self.assertEqual(len(docker_builds), 1)

        original = json.loads((artifact_root / "results" / "demo-host" / "original.json").read_text())
        safe = json.loads((artifact_root / "results" / "demo-host" / "safe.json").read_text())
        original_summary_path = artifact_root / original["downstream_summary_path"]
        safe_summary_path = artifact_root / safe["downstream_summary_path"]
        original_summary = json.loads(original_summary_path.read_text())
        safe_summary = json.loads(safe_summary_path.read_text())

        self.assertEqual(original["status"], "passed")
        self.assertEqual(safe["status"], "passed")
        self.assertEqual(original["execution_strategy"], "host-harness")
        self.assertEqual(safe["execution_strategy"], "host-harness")
        self.assertEqual(original["downstream_summary_path"], "downstream/demo-host/original/summary.json")
        self.assertEqual(safe["downstream_summary_path"], "downstream/demo-host/safe/summary.json")
        self.assertIsNone(original["cast_path"])
        self.assertEqual(safe["cast_path"], "casts/demo-host/safe.cast")
        self.assertTrue((artifact_root / safe["cast_path"]).is_file())
        self.assertTrue((artifact_root / safe["log_path"]).is_file())

        self.assertEqual(original_summary["report_format"], "validator-wrapper-baseline")
        self.assertEqual(original_summary["expected_dependents"], 2)
        self.assertEqual(
            original_summary["selected_dependents"],
            ["baseline-image", "scratch-git-index"],
        )
        self.assertEqual(
            original_summary["passed_dependents"],
            ["baseline-image", "scratch-git-index"],
        )
        self.assertEqual(
            original_summary["artifacts"]["raw_results"],
            "downstream/demo-host/original/raw/results.json",
        )
        self.assertEqual(
            safe_summary["report_format"],
            "imported-log-marker",
        )
        self.assertEqual(safe_summary["expected_dependents"], 1)
        self.assertEqual(safe_summary["selected_dependents"], ["safe-deb-fixture"])
        self.assertEqual(safe_summary["passed_dependents"], ["safe-deb-fixture"])
        self.assertEqual(
            safe_summary["artifacts"]["raw_results"],
            "downstream/demo-host/safe/raw/results.json",
        )

        original_scratch = artifact_root / ".workspace" / "host-harness" / "demo-host" / "original" / "repo"
        safe_scratch = artifact_root / ".workspace" / "host-harness" / "demo-host" / "safe" / "repo"
        self.assertTrue((original_scratch / "test-original.sh").is_file())
        self.assertTrue((original_scratch / "safe" / "debian" / "control").is_file())
        self.assertTrue((original_scratch / "original" / "marker.txt").is_file())
        self.assertTrue((original_scratch / "safe" / "marker.txt").is_file())
        self.assertTrue((original_scratch / "build-check-install" / "marker.txt").is_file())
        self.assertEqual(
            subprocess.run(
                ["git", "ls-files", "--error-unmatch", "build-check-install/marker.txt"],
                cwd=original_scratch,
                check=False,
                text=True,
                capture_output=True,
            ).returncode,
            0,
        )
        self.assertIn(
            "scratch-mutated:original",
            (original_scratch / "build-check-install" / "marker.txt").read_text(),
        )
        self.assertIn(
            "scratch-mutated:safe",
            (safe_scratch / "build-check-install" / "marker.txt").read_text(),
        )
        staged_debs = sorted(path.name for path in (safe_scratch / "safe" / "dist").glob("*.deb"))
        self.assertEqual(staged_debs, ["demo-host-safe-marker_1.0_all.deb"])

        self.assertEqual(
            (fixture_root / "tests" / "tagged-port" / "build-check-install" / "marker.txt").read_text(),
            "build-check-install-marker\n",
        )
        self.assertEqual(
            (fixture_root / "tests" / "tagged-port" / "original" / "marker.txt").read_text(),
            "original-marker\n",
        )
        self.assertEqual(
            (fixture_root / "tests" / "tagged-port" / "safe" / "marker.txt").read_text(),
            "safe-marker\n",
        )

    def test_write_summary_requires_notes_for_setup_stage_failure(self) -> None:
        root = self.run_root()
        summary_path = root / "artifacts" / "downstream" / "demo-host" / "safe" / "summary.json"
        payload = {
            "summary_version": 1,
            "library": "demo-host",
            "mode": "safe",
            "status": "failed",
            "report_format": "imported-log-marker",
            "expected_dependents": 3,
            "selected_dependents": [],
            "passed_dependents": [],
            "failed_dependents": [],
            "warned_dependents": [],
            "skipped_dependents": [],
            "artifacts": {},
        }

        with self.assertRaisesRegex(ValidatorError, "notes are required for setup-stage failures"):
            write_summary(summary_path=summary_path, payload=payload)

        payload["notes"] = "setup failed before the first workload marker"
        write_summary(summary_path=summary_path, payload=payload)

        summary = json.loads(summary_path.read_text())
        self.assertEqual(summary["status"], "failed")
        self.assertEqual(summary["expected_dependents"], 3)
        self.assertEqual(summary["selected_dependents"], [])
        self.assertEqual(summary["notes"], payload["notes"])


if __name__ == "__main__":
    unittest.main()
