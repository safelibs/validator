from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools import ValidatorError
from tools import import_port_assets, verify_imported_assets
from unit import commit_all, init_repo, repository_entry


class VerifyImportedAssetsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name)
        self.port_root = self.root / "ports"
        self.workspace = self.root / "workspace"
        self.dest_root = self.root / "dest"
        self.tests_root = self.dest_root / "tests"
        self.stage_repo = self.port_root / "libdemo"
        init_repo(self.stage_repo)
        (self.stage_repo / "safe" / "debian").mkdir(parents=True, exist_ok=True)
        (self.stage_repo / "safe" / "debian" / "control").write_text("Source: libdemo\n")
        (self.stage_repo / "safe" / "tests" / "case.txt").parent.mkdir(parents=True, exist_ok=True)
        (self.stage_repo / "safe" / "tests" / "case.txt").write_text("case\n")
        (self.stage_repo / "safe" / "tests" / "nested" / "subcase.txt").parent.mkdir(
            parents=True, exist_ok=True
        )
        (self.stage_repo / "safe" / "tests" / "nested" / "subcase.txt").write_text("subcase\n")
        (self.stage_repo / "original" / "header.h").parent.mkdir(parents=True, exist_ok=True)
        (self.stage_repo / "original" / "header.h").write_text("#define DEMO 1\n")
        (self.stage_repo / "dependents.json").write_text('{"demo": true}\n')
        (self.stage_repo / "relevant_cves.json").write_text("[]\n")
        (self.stage_repo / "test-original.sh").write_text("#!/bin/sh\n")
        commit_all(self.stage_repo, "initial")

        self.manifest = {
            "archive": {"suite": "noble"},
            "inventory": {"tag_probe_rule": "refs/tags/{library}/04-test"},
            "repositories": [
                repository_entry(
                    "libdemo",
                    imports=["safe/tests", "original/header.h"],
                )
            ],
        }
        import_port_assets.import_library_assets(
            self.manifest,
            library="libdemo",
            port_root=self.port_root,
            workspace=self.workspace,
            dest_root=self.dest_root,
        )

    def verify(self) -> None:
        verify_imported_assets.verify_library_assets(
            self.manifest,
            library="libdemo",
            port_root=self.port_root,
            workspace=self.workspace,
            tests_root=self.tests_root,
        )

    def test_verify_accepts_matching_directory_and_file_imports(self) -> None:
        self.verify()

    def test_verify_rejects_extra_file_under_tagged_port(self) -> None:
        extra = self.tests_root / "libdemo" / "tests" / "tagged-port" / "extra.txt"
        extra.write_text("extra\n")

        with self.assertRaisesRegex(ValidatorError, "tagged-port mismatch"):
            self.verify()

    def test_verify_rejects_extra_file_under_fixtures(self) -> None:
        extra = self.tests_root / "libdemo" / "tests" / "fixtures" / "extra.json"
        extra.write_text("{}\n")

        with self.assertRaisesRegex(ValidatorError, "fixtures mismatch"):
            self.verify()

    def test_verify_rejects_extra_file_under_harness_source(self) -> None:
        extra = self.tests_root / "libdemo" / "tests" / "harness-source" / "extra.txt"
        extra.write_text("extra\n")

        with self.assertRaisesRegex(ValidatorError, "harness-source mismatch"):
            self.verify()

    def test_verify_rejects_fixture_or_harness_drift(self) -> None:
        for relative_path, expected_error in [
            (Path("fixtures/dependents.json"), "content drift detected"),
            (Path("harness-source/original-test-script.sh"), "content drift detected"),
        ]:
            with self.subTest(relative_path=relative_path):
                target = self.tests_root / "libdemo" / "tests" / relative_path
                target.write_text("drift\n")
                with self.assertRaisesRegex(ValidatorError, expected_error):
                    self.verify()
                import_port_assets.import_library_assets(
                    self.manifest,
                    library="libdemo",
                    port_root=self.port_root,
                    workspace=self.workspace,
                    dest_root=self.dest_root,
                )

    def test_verify_rejects_missing_imported_files(self) -> None:
        for relative_path, expected_error in [
            (Path("fixtures/dependents.json"), "fixtures mismatch"),
            (Path("harness-source/original-test-script.sh"), "harness-source mismatch"),
            (Path("tagged-port/original/header.h"), "tagged-port mismatch"),
        ]:
            with self.subTest(relative_path=relative_path):
                target = self.tests_root / "libdemo" / "tests" / relative_path
                target.unlink()
                with self.assertRaisesRegex(ValidatorError, expected_error):
                    self.verify()
                import_port_assets.import_library_assets(
                    self.manifest,
                    library="libdemo",
                    port_root=self.port_root,
                    workspace=self.workspace,
                    dest_root=self.dest_root,
                )

    def test_verify_rejects_missing_source_file(self) -> None:
        (self.stage_repo / "original" / "header.h").unlink()

        with self.assertRaisesRegex(ValidatorError, "missing source file"):
            self.verify()

    def test_verify_supports_libuv_source_overrides(self) -> None:
        compat_root = self.root / "compat"
        workspace = compat_root / "workspace"
        port_root = compat_root / "ports"
        dest_root = compat_root / "dest"
        stage_repo = port_root / "libuv"
        init_repo(stage_repo)
        (stage_repo / "safe" / "debian").mkdir(parents=True, exist_ok=True)
        (stage_repo / "safe" / "debian" / "control").write_text("Source: libuv\n")
        (stage_repo / "safe" / "docker" / "Dockerfile.dependents").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "docker" / "Dockerfile.dependents").write_text("FROM ubuntu:24.04\n")
        (stage_repo / "safe" / "tools" / "build_upstream_harness.sh").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "tools" / "build_upstream_harness.sh").write_text("#!/bin/sh\n")
        (stage_repo / "safe" / "tools" / "run_regressions.sh").write_text("#!/bin/sh\n")
        (stage_repo / "safe" / "tests" / "upstream" / "test" / "run-tests.c").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "tests" / "upstream" / "test" / "run-tests.c").write_text(
            "int main(void) { return 0; }\n"
        )
        (stage_repo / "safe" / "tests" / "regressions" / "fs_readlink_proc_self.c").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "tests" / "regressions" / "fs_readlink_proc_self.c").write_text(
            "int fs_readlink_proc_self(void) { return 0; }\n"
        )
        (stage_repo / "safe" / "tests" / "regressions" / "manifest.json").write_text("{}\n")
        (stage_repo / "safe" / "tests" / "harness" / "uv-safe-run-tests.c").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "tests" / "harness" / "uv-safe-run-tests.c").write_text(
            "int run_regressions(void) { return 0; }\n"
        )
        (stage_repo / "safe" / "include" / "uv.h").parent.mkdir(parents=True, exist_ok=True)
        (stage_repo / "safe" / "include" / "uv.h").write_text("#define UV_VERSION 1\n")
        (stage_repo / "dependents.json").write_text('{"uv": true}\n')
        (stage_repo / "relevant_cves.json").write_text("[]\n")
        (stage_repo / "test-original.sh").write_text("#!/bin/sh\n")
        commit_all(stage_repo, "initial")

        (
            workspace
            / "build-safe"
            / "libuv"
            / "source"
            / "safe"
            / "target"
            / "release"
            / "libuv.a"
        ).parent.mkdir(parents=True, exist_ok=True)
        (
            workspace
            / "build-safe"
            / "libuv"
            / "source"
            / "safe"
            / "target"
            / "release"
            / "libuv.a"
        ).write_bytes(b"runtime-support")

        manifest = {
            "archive": {"suite": "noble"},
            "inventory": {"tag_probe_rule": "refs/tags/{library}/04-test"},
            "repositories": [
                repository_entry(
                    "libuv",
                    imports=[
                        "safe/docker",
                        "safe/include",
                        "safe/prebuilt",
                        "safe/scripts",
                        "safe/test",
                        "safe/test-extra",
                    ],
                )
            ],
        }

        import_port_assets.import_library_assets(
            manifest,
            library="libuv",
            port_root=port_root,
            workspace=workspace,
            dest_root=dest_root,
        )

        verify_imported_assets.verify_library_assets(
            manifest,
            library="libuv",
            port_root=port_root,
            workspace=workspace,
            tests_root=dest_root / "tests",
        )

        (
            dest_root
            / "tests"
            / "libuv"
            / "tests"
            / "tagged-port"
            / "safe"
            / "prebuilt"
            / "x86_64-unknown-linux-gnu"
            / "libuv_safe_runtime_support.a"
        ).write_bytes(b"drift\n")

        with self.assertRaisesRegex(ValidatorError, "content drift detected"):
            verify_imported_assets.verify_library_assets(
                manifest,
                library="libuv",
                port_root=port_root,
                workspace=workspace,
                tests_root=dest_root / "tests",
            )


if __name__ == "__main__":
    unittest.main()
