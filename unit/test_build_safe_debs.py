from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import ValidatorError
from tools import build_safe_debs
from unit import commit_all, init_repo, repository_entry, run_git


def completed(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.CompletedProcess(args=args, returncode=0, stdout="", stderr="")


class BuildSafeDebsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name)
        self.port_root = self.root / "ports"
        self.workspace = self.root / "workspace"
        self.output = self.root / "output"
        self.stage_repo = self.port_root / "libdemo"
        init_repo(self.stage_repo)
        (self.stage_repo / "safe" / "debian").mkdir(parents=True, exist_ok=True)
        (self.stage_repo / "safe" / "debian" / "control").write_text("Source: libdemo\n")
        (self.stage_repo / "safe" / "tools").mkdir(parents=True, exist_ok=True)
        (
            self.stage_repo / "safe" / "tools" / "cc-linker.sh"
        ).write_text('python3 "/home/yans/safelibs/port-libdemo/safe/tools/abi-baseline.json"\n')
        (self.stage_repo / "build.sh").write_text("echo build\n")
        (self.stage_repo / "cargo" / "Cargo.toml").parent.mkdir(parents=True, exist_ok=True)
        (self.stage_repo / "cargo" / "Cargo.toml").write_text('[package]\nedition = "2021"\n')
        (self.stage_repo / "artifact.deb").write_bytes(b"checked-in-deb")
        commit_all(self.stage_repo, "initial")

    def manifest(self, build: dict[str, object]) -> dict[str, object]:
        return {
            "archive": {
                "image": "ubuntu:24.04",
                "install_packages": ["git", "python3"],
            },
            "inventory": {"tag_probe_rule": "refs/tags/{library}/04-test"},
            "repositories": [repository_entry("libdemo", imports=["safe/tests"], build=build)],
        }

    def git_status(self) -> str:
        return run_git(["status", "--porcelain"], cwd=self.stage_repo, capture_output=True).stdout

    def fake_docker_run(self, commands: list[list[str]], artifact_name: str) -> mock.Mock:
        def side_effect(args: list[str], **kwargs: object) -> subprocess.CompletedProcess[str]:
            commands.append(args)
            mounts = [value for value in args if value.startswith("type=bind,src=")]
            source_mount = next(value for value in mounts if value.endswith(",dst=/workspace/source"))
            output_mount = next(value for value in mounts if value.endswith(",dst=/workspace/output"))
            source_dir = Path(
                source_mount.split(",src=", 1)[1].rsplit(",dst=/workspace/source", 1)[0]
            )
            output_dir = Path(
                output_mount.split(",src=", 1)[1].rsplit(",dst=/workspace/output", 1)[0]
            )
            (source_dir / "scratch-mutated.txt").write_text("scratch only\n")
            (output_dir / artifact_name).write_bytes(b"deb")
            env = kwargs["env"]
            assert env["SAFEAPTREPO_SOURCE"] == "/workspace/source"
            assert env["SAFEAPTREPO_OUTPUT"] == "/workspace/output"
            assert env["SAFEDEBREPO_SOURCE"] == "/workspace/source"
            assert env["SAFEDEBREPO_OUTPUT"] == "/workspace/output"
            return completed(args)

        return mock.Mock(side_effect=side_effect)

    def test_safe_debian_build_uses_scratch_copy_and_leaves_stage_clean(self) -> None:
        commands: list[list[str]] = []
        fake_run = self.fake_docker_run(commands, "libdemo-safe.deb")
        with mock.patch("tools.build_safe_debs.run", fake_run):
            artifacts = build_safe_debs.build_library(
                self.manifest({"mode": "safe-debian", "artifact_globs": ["*.deb"]}),
                library="libdemo",
                port_root=self.port_root,
                workspace=self.workspace,
                output=self.output,
            )

        self.assertEqual([artifact.name for artifact in artifacts], ["libdemo-safe.deb"])
        self.assertEqual(self.git_status(), "")
        self.assertFalse((self.stage_repo / "scratch-mutated.txt").exists())
        scratch_linker = (
            build_safe_debs.scratch_source_for(self.workspace, "libdemo")
            / "safe"
            / "tools"
            / "cc-linker.sh"
        )
        self.assertIn("/workspace/source/safe/tools/abi-baseline.json", scratch_linker.read_text())
        self.assertNotIn("/home/yans/safelibs/port-libdemo", scratch_linker.read_text())
        self.assertIn("/home/yans/safelibs/port-libdemo", (self.stage_repo / "safe" / "tools" / "cc-linker.sh").read_text())
        self.assertIn("Acquire::ForceIPv4=true", commands[0][-1])
        self.assertIn("Acquire::Retries=3", commands[0][-1])
        self.assertIn("Acquire::http::Timeout=30", commands[0][-1])
        self.assertIn("Acquire::https::Timeout=30", commands[0][-1])
        self.assertIn('mk-build-deps -i -r -t "apt-get -o Acquire::ForceIPv4=true', commands[0][-1])
        self.assertNotIn('mk-build-deps -i -r -t "apt-get -o Acquire::ForceIPv4=true -o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 install', commands[0][-1])
        self.assertIn("dpkg-buildpackage -us -uc -b", commands[0][-1])
        self.assertTrue(fake_run.call_args.kwargs["capture_output"])

    def test_patch_scratch_copy_for_libvips_removes_incompatible_symbol_from_scratch_only(self) -> None:
        scratch_source = self.workspace / "build-safe" / "libvips" / "source"
        symbols_path = scratch_source / "safe" / "reference" / "abi" / "libvips.symbols"
        symbols_path.parent.mkdir(parents=True, exist_ok=True)
        original_text = "VIPS_8.15 {\nkeep_symbol\nlzw_context_create\n}\n"
        symbols_path.write_text(original_text, encoding="utf-8")

        build_safe_debs.patch_scratch_copy_for_library(scratch_source, "libvips")

        self.assertEqual(
            symbols_path.read_text(encoding="utf-8"),
            "VIPS_8.15 {\nkeep_symbol\n}\n",
        )

    def test_patch_scratch_copy_for_library_ignores_other_libraries(self) -> None:
        scratch_source = self.workspace / "build-safe" / "libdemo" / "source"
        symbols_path = scratch_source / "safe" / "reference" / "abi" / "libvips.symbols"
        symbols_path.parent.mkdir(parents=True, exist_ok=True)
        original_text = "keep_symbol\nlzw_context_create\n"
        symbols_path.write_text(original_text, encoding="utf-8")

        build_safe_debs.patch_scratch_copy_for_library(scratch_source, "libdemo")

        self.assertEqual(symbols_path.read_text(encoding="utf-8"), original_text)

    def test_checkout_artifacts_copies_declared_debs(self) -> None:
        artifacts = build_safe_debs.build_library(
            self.manifest(
                {
                    "mode": "checkout-artifacts",
                    "workdir": ".",
                    "artifact_globs": ["*.deb"],
                }
            ),
            library="libdemo",
            port_root=self.port_root,
            workspace=self.workspace,
            output=self.output,
        )

        self.assertEqual([artifact.name for artifact in artifacts], ["artifact.deb"])
        self.assertEqual((self.output / "artifact.deb").read_bytes(), b"checked-in-deb")
        self.assertEqual(self.git_status(), "")

    def test_explicit_docker_mode_runs_configured_command(self) -> None:
        commands: list[list[str]] = []
        fake_run = self.fake_docker_run(commands, "libdemo-docker.deb")
        with mock.patch("tools.build_safe_debs.run", fake_run):
            build_safe_debs.build_library(
                self.manifest(
                    {
                        "mode": "docker",
                        "workdir": ".",
                        "command": "./build.sh",
                        "artifact_globs": ["*.deb"],
                    }
                ),
                library="libdemo",
                port_root=self.port_root,
                workspace=self.workspace,
                output=self.output,
            )

        self.assertIn("./build.sh", commands[0][-1])

    def test_omitted_mode_defaults_to_docker(self) -> None:
        commands: list[list[str]] = []
        fake_run = self.fake_docker_run(commands, "libdemo-default.deb")
        with mock.patch("tools.build_safe_debs.run", fake_run):
            build_safe_debs.build_library(
                self.manifest(
                    {
                        "workdir": ".",
                        "command": "bash build.sh",
                        "artifact_globs": ["*.deb"],
                    }
                ),
                library="libdemo",
                port_root=self.port_root,
                workspace=self.workspace,
                output=self.output,
            )

        self.assertIn("bash build.sh", commands[0][-1])

    def test_unsupported_mode_fails(self) -> None:
        with self.assertRaisesRegex(ValidatorError, "unsupported build mode"):
            build_safe_debs.build_library(
                self.manifest({"mode": "custom", "artifact_globs": ["*.deb"]}),
                library="libdemo",
                port_root=self.port_root,
                workspace=self.workspace,
                output=self.output,
            )

    def test_missing_library_fails(self) -> None:
        with self.assertRaisesRegex(ValidatorError, "unknown libraries in config"):
            build_safe_debs.build_library(
                self.manifest({"mode": "checkout-artifacts", "artifact_globs": ["*.deb"]}),
                library="missing",
                port_root=self.port_root,
                workspace=self.workspace,
                output=self.output,
            )

    def test_missing_staged_checkout_fails(self) -> None:
        shutil.rmtree(self.stage_repo)

        with self.assertRaisesRegex(ValidatorError, "missing staged checkout"):
            build_safe_debs.build_library(
                self.manifest({"mode": "checkout-artifacts", "artifact_globs": ["*.deb"]}),
                library="libdemo",
                port_root=self.port_root,
                workspace=self.workspace,
                output=self.output,
            )

    def test_missing_workdir_fails(self) -> None:
        with self.assertRaisesRegex(ValidatorError, "missing workdir"):
            build_safe_debs.build_library(
                self.manifest(
                    {
                        "mode": "checkout-artifacts",
                        "workdir": "missing",
                        "artifact_globs": ["*.deb"],
                    }
                ),
                library="libdemo",
                port_root=self.port_root,
                workspace=self.workspace,
                output=self.output,
            )

    def test_missing_artifacts_fails(self) -> None:
        with mock.patch("tools.build_safe_debs.run", return_value=completed(["docker", "run"])):
            with self.assertRaisesRegex(ValidatorError, "no declared artifacts were produced"):
                build_safe_debs.build_library(
                    self.manifest(
                        {
                            "mode": "docker",
                            "workdir": ".",
                            "command": "./build.sh",
                            "artifact_globs": ["*.deb"],
                        }
                    ),
                    library="libdemo",
                    port_root=self.port_root,
                    workspace=self.workspace,
                    output=self.output,
                )


if __name__ == "__main__":
    unittest.main()
