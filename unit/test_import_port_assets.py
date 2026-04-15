from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools import ValidatorError, import_port_assets
from unit import commit_all, init_repo, repository_entry


class ImportPortAssetsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.root = Path(self.tempdir.name)
        self.port_root = self.root / "ports"
        self.workspace = self.root / "workspace"
        self.dest_root = self.root / "dest"
        self.stage_repo = self.port_root / "libdemo"
        init_repo(self.stage_repo)
        (self.stage_repo / "safe" / "debian").mkdir(parents=True, exist_ok=True)
        (self.stage_repo / "safe" / "debian" / "control").write_text("Source: libdemo\n")
        (self.stage_repo / "safe" / "tests" / "case.txt").parent.mkdir(parents=True, exist_ok=True)
        (self.stage_repo / "safe" / "tests" / "case.txt").write_bytes(b"case-bytes\n")
        (self.stage_repo / "safe" / "tests" / "ok" / "nested.txt").parent.mkdir(
            parents=True, exist_ok=True
        )
        (self.stage_repo / "safe" / "tests" / "ok" / "nested.txt").write_text("nested\n")
        (self.stage_repo / "safe" / "tests" / "build" / "skip.txt").parent.mkdir(
            parents=True, exist_ok=True
        )
        (self.stage_repo / "safe" / "tests" / "build" / "skip.txt").write_text("skip\n")
        (self.stage_repo / "safe" / "tests" / "node_modules" / "skip.js").parent.mkdir(
            parents=True, exist_ok=True
        )
        (self.stage_repo / "safe" / "tests" / "node_modules" / "skip.js").write_text("skip\n")
        (self.stage_repo / "original" / "header.h").parent.mkdir(parents=True, exist_ok=True)
        (self.stage_repo / "original" / "header.h").write_text("#define DEMO 1\n")
        (self.stage_repo / "dependents.json").write_text('{"demo": true}\n')
        (self.stage_repo / "relevant_cves.json").write_text("[]\n")
        (self.stage_repo / "test-original.sh").write_text("#!/bin/sh\n")
        commit_all(self.stage_repo, "initial")
        (self.stage_repo / "safe" / "tests" / "untracked.txt").write_text("untracked\n")

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

    def test_import_library_assets_copies_declared_tracked_files_only(self) -> None:
        import_port_assets.import_library_assets(
            self.manifest,
            library="libdemo",
            port_root=self.port_root,
            workspace=self.workspace,
            dest_root=self.dest_root,
        )

        tests_root = self.dest_root / "tests" / "libdemo" / "tests"
        self.assertEqual(
            (tests_root / "fixtures" / "dependents.json").read_text(),
            '{"demo": true}\n',
        )
        self.assertEqual(
            (tests_root / "harness-source" / "original-test-script.sh").read_text(),
            "#!/bin/sh\n",
        )
        self.assertEqual(
            (tests_root / "tagged-port" / "safe" / "tests" / "case.txt").read_bytes(),
            b"case-bytes\n",
        )
        self.assertTrue((tests_root / "tagged-port" / "safe" / "tests" / "ok" / "nested.txt").is_file())
        self.assertTrue((tests_root / "tagged-port" / "original" / "header.h").is_file())
        self.assertFalse((tests_root / "tagged-port" / "safe" / "tests" / "build").exists())
        self.assertFalse(
            (tests_root / "tagged-port" / "safe" / "tests" / "node_modules").exists()
        )
        self.assertFalse(
            (tests_root / "tagged-port" / "safe" / "tests" / "untracked.txt").exists()
        )

    def test_import_library_assets_preserves_validator_owned_library_siblings_on_rerun(self) -> None:
        import_port_assets.import_library_assets(
            self.manifest,
            library="libdemo",
            port_root=self.port_root,
            workspace=self.workspace,
            dest_root=self.dest_root,
        )

        library_root = self.dest_root / "tests" / "libdemo"
        (library_root / "Dockerfile").write_text("FROM ubuntu:24.04\n")
        (library_root / "docker-entrypoint.sh").write_text("#!/bin/sh\n")
        (library_root / "tests" / "run.sh").write_text("#!/bin/sh\n")
        (library_root / "tests" / "tagged-port" / "stale.txt").write_text("stale\n")

        import_port_assets.import_library_assets(
            self.manifest,
            library="libdemo",
            port_root=self.port_root,
            workspace=self.workspace,
            dest_root=self.dest_root,
        )

        self.assertEqual((library_root / "Dockerfile").read_text(), "FROM ubuntu:24.04\n")
        self.assertEqual((library_root / "docker-entrypoint.sh").read_text(), "#!/bin/sh\n")
        self.assertEqual((library_root / "tests" / "run.sh").read_text(), "#!/bin/sh\n")
        self.assertFalse((library_root / "tests" / "tagged-port" / "stale.txt").exists())
        self.assertTrue((library_root / "tests" / "fixtures" / "dependents.json").is_file())

    def test_import_library_assets_supports_libuv_source_overrides(self) -> None:
        stage_repo = self.port_root / "libuv"
        init_repo(stage_repo)
        (stage_repo / "safe" / "debian").mkdir(parents=True, exist_ok=True)
        (stage_repo / "safe" / "debian" / "control").write_text("Source: libuv\n")
        (stage_repo / "safe" / "docker" / "Dockerfile.dependents").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "docker" / "Dockerfile.dependents").write_text("FROM ubuntu:24.04\n")
        (stage_repo / "safe" / "docker" / "run-dependent-probes.sh").write_text("#!/bin/sh\n")
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
        (stage_repo / "safe" / "tests" / "dependents" / "manifest.json").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "tests" / "dependents" / "manifest.json").write_text("{}\n")
        (stage_repo / "safe" / "tests" / "dependents" / "common.sh").write_text("#!/bin/sh\n")
        (stage_repo / "safe" / "tests" / "dependents" / "probes" / "http.sh").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "tests" / "dependents" / "probes" / "http.sh").write_text(
            "#!/bin/sh\n"
        )
        (stage_repo / "safe" / "include" / "uv.h").parent.mkdir(parents=True, exist_ok=True)
        (stage_repo / "safe" / "include" / "uv.h").write_text("#define UV_VERSION 1\n")
        (stage_repo / "original" / "README.md").parent.mkdir(parents=True, exist_ok=True)
        (stage_repo / "original" / "README.md").write_text("original source\n")
        (stage_repo / "original" / "src" / "uv.c").parent.mkdir(parents=True, exist_ok=True)
        (stage_repo / "original" / "src" / "uv.c").write_text("int uv_original(void) { return 0; }\n")
        (stage_repo / "dependents.json").write_text('{"uv": true}\n')
        (stage_repo / "relevant_cves.json").write_text("[]\n")
        (stage_repo / "test-original.sh").write_text("#!/bin/sh\n")
        commit_all(stage_repo, "initial")

        (
            self.workspace
            / "build-safe"
            / "libuv"
            / "source"
            / "safe"
            / "target"
            / "release"
            / "libuv.a"
        ).parent.mkdir(parents=True, exist_ok=True)
        (
            self.workspace
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
                        "safe/tests/dependents",
                        "original",
                    ],
                )
            ],
        }

        import_port_assets.import_library_assets(
            manifest,
            library="libuv",
            port_root=self.port_root,
            workspace=self.workspace,
            dest_root=self.dest_root,
        )

        tests_root = self.dest_root / "tests" / "libuv" / "tests"
        self.assertEqual(
            (
                tests_root / "tagged-port" / "safe" / "docker" / "dependents.Dockerfile"
            ).read_text(),
            "FROM ubuntu:24.04\n",
        )
        self.assertEqual(
            (
                tests_root
                / "tagged-port"
                / "safe"
                / "prebuilt"
                / "x86_64-unknown-linux-gnu"
                / "libuv_safe_runtime_support.a"
            ).read_bytes(),
            b"runtime-support",
        )
        self.assertEqual(
            (tests_root / "tagged-port" / "safe" / "scripts" / "build_upstream_harness.sh").read_text(),
            "#!/bin/sh\n",
        )
        self.assertEqual(
            (tests_root / "tagged-port" / "safe" / "scripts" / "run_regressions.sh").read_text(),
            "#!/bin/sh\n",
        )
        self.assertEqual(
            (tests_root / "tagged-port" / "safe" / "test" / "run-tests.c").read_text(),
            "int main(void) { return 0; }\n",
        )
        self.assertEqual(
            (tests_root / "tagged-port" / "safe" / "test-extra" / "run-regressions.c").read_text(),
            "int run_regressions(void) { return 0; }\n",
        )
        self.assertEqual(
            (
                tests_root / "tagged-port" / "safe" / "test-extra" / "fs_readlink_proc_self.c"
            ).read_text(),
            "int fs_readlink_proc_self(void) { return 0; }\n",
        )
        self.assertEqual(
            (
                tests_root / "tagged-port" / "safe" / "tests" / "dependents" / "manifest.json"
            ).read_text(),
            "{}\n",
        )
        self.assertEqual(
            (
                tests_root / "tagged-port" / "safe" / "tests" / "dependents" / "common.sh"
            ).read_text(),
            "#!/bin/sh\n",
        )
        self.assertEqual(
            (
                tests_root
                / "tagged-port"
                / "safe"
                / "tests"
                / "dependents"
                / "probes"
                / "http.sh"
            ).read_text(),
            "#!/bin/sh\n",
        )
        self.assertEqual(
            (tests_root / "tagged-port" / "original" / "README.md").read_text(),
            "original source\n",
        )
        self.assertEqual(
            (tests_root / "tagged-port" / "original" / "src" / "uv.c").read_text(),
            "int uv_original(void) { return 0; }\n",
        )

    def test_import_library_assets_requires_libuv_build_output_for_prebuilt_override(self) -> None:
        stage_repo = self.port_root / "libuv"
        init_repo(stage_repo)
        (stage_repo / "safe" / "debian").mkdir(parents=True, exist_ok=True)
        (stage_repo / "safe" / "debian" / "control").write_text("Source: libuv\n")
        (stage_repo / "safe" / "docker" / "Dockerfile.dependents").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "docker" / "Dockerfile.dependents").write_text("FROM ubuntu:24.04\n")
        (stage_repo / "safe" / "include" / "uv.h").parent.mkdir(parents=True, exist_ok=True)
        (stage_repo / "safe" / "include" / "uv.h").write_text("#define UV_VERSION 1\n")
        (stage_repo / "safe" / "tools" / "build_upstream_harness.sh").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "tools" / "build_upstream_harness.sh").write_text("#!/bin/sh\n")
        (stage_repo / "safe" / "tests" / "upstream" / "test" / "run-tests.c").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "tests" / "upstream" / "test" / "run-tests.c").write_text(
            "int main(void) { return 0; }\n"
        )
        (stage_repo / "safe" / "tests" / "regressions" / "manifest.json").parent.mkdir(
            parents=True,
            exist_ok=True,
        )
        (stage_repo / "safe" / "tests" / "regressions" / "manifest.json").write_text("{}\n")
        (stage_repo / "safe" / "tests" / "harness" / "uv-safe-run-tests.c").parent.mkdir(
            parents=True, exist_ok=True
        )
        (stage_repo / "safe" / "tests" / "harness" / "uv-safe-run-tests.c").write_text(
            "int run_regressions(void) { return 0; }\n"
        )
        (stage_repo / "dependents.json").write_text('{"uv": true}\n')
        (stage_repo / "relevant_cves.json").write_text("[]\n")
        (stage_repo / "test-original.sh").write_text("#!/bin/sh\n")
        commit_all(stage_repo, "initial")

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
                        "safe/tests/dependents",
                        "original",
                    ],
                )
            ],
        }

        with self.assertRaisesRegex(ValidatorError, "missing libuv prebuilt runtime support archive"):
            import_port_assets.import_library_assets(
                manifest,
                library="libuv",
                port_root=self.port_root,
                workspace=self.workspace,
                dest_root=self.dest_root,
            )


if __name__ == "__main__":
    unittest.main()
