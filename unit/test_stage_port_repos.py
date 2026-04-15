from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest import mock

from tools import ValidatorError
from tools import inventory
from tools import stage_port_repos
from tools import github_auth
from unit import commit_all, init_repo, repository_entry, run_git, write_manifest


def create_remote_repo(root: Path, name: str, *, tag_after_clone: bool) -> tuple[Path, Path]:
    remote = root / f"{name}.git"
    work = root / f"{name}-work"
    run_git(["init", "--bare", str(remote)], cwd=root)
    init_repo(work)
    (work / "safe" / "debian").mkdir(parents=True, exist_ok=True)
    (work / "safe" / "debian" / "control").write_text(f"Source: {name}\n")
    (work / "safe" / "tests" / "smoke.txt").parent.mkdir(parents=True, exist_ok=True)
    (work / "safe" / "tests" / "smoke.txt").write_text(f"{name}\n")
    commit_all(work, "initial")
    run_git(["remote", "add", "origin", str(remote)], cwd=work)
    run_git(["push", "origin", "HEAD:refs/heads/main"], cwd=work)
    if not tag_after_clone:
        run_git(["tag", f"{name}/04-test"], cwd=work)
        run_git(["push", "origin", f"refs/tags/{name}/04-test"], cwd=work)
    return remote, work


def create_libvips_remote_repo(root: Path) -> tuple[Path, Path]:
    remote = root / "libvips.git"
    work = root / "libvips-work"
    run_git(["init", "--bare", str(remote)], cwd=root)
    init_repo(work)
    (work / "safe" / "debian").mkdir(parents=True, exist_ok=True)
    (work / "safe" / "debian" / "control").write_text("Source: libvips\n")
    (work / "safe" / "include" / "vips").mkdir(parents=True, exist_ok=True)
    (work / "safe" / "include" / "vips" / "vips.h").write_text("#define VIPS_VERSION \"8.15.1\"\n")
    (work / "safe" / "reference" / "pkgconfig").mkdir(parents=True, exist_ok=True)
    (work / "safe" / "reference" / "pkgconfig" / "vips.pc").write_text(
        "prefix=/tmp/build-check-install\nincludedir=${prefix}/include\nlibdir=${prefix}/lib\n"
    )
    (work / "safe" / "reference" / "pkgconfig" / "vips-cpp.pc").write_text(
        "prefix=/tmp/build-check-install\nincludedir=${prefix}/include\nlibdir=${prefix}/lib\n"
    )
    commit_all(work, "initial")
    run_git(["remote", "add", "origin", str(remote)], cwd=work)
    run_git(["push", "origin", "HEAD:refs/heads/main"], cwd=work)
    run_git(["tag", "libvips/04-test"], cwd=work)
    run_git(["push", "origin", "refs/tags/libvips/04-test"], cwd=work)
    return remote, work


class StagePortReposTests(unittest.TestCase):
    def test_stage_from_source_root_uses_local_tags_and_exact_remote_fetch_for_missing_tags(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source_root = tmp_path / "source"
            source_root.mkdir()
            workspace = tmp_path / "workspace"
            dest_root = tmp_path / "staged"

            libexif_remote, _ = create_remote_repo(tmp_path, "libexif", tag_after_clone=False)
            run_git(["clone", str(libexif_remote), str(source_root / "port-libexif")], cwd=tmp_path)

            libuv_remote, libuv_work = create_remote_repo(tmp_path, "libuv", tag_after_clone=True)
            run_git(["clone", str(libuv_remote), str(source_root / "port-libuv")], cwd=tmp_path)
            (
                source_root
                / "port-libuv"
                / "safe"
                / "target"
                / "release"
                / "libuv.a"
            ).parent.mkdir(parents=True, exist_ok=True)
            (
                source_root
                / "port-libuv"
                / "safe"
                / "target"
                / "release"
                / "libuv.a"
            ).write_bytes(b"runtime-support\n")
            run_git(["tag", "libuv/04-test"], cwd=libuv_work)
            run_git(["push", "origin", "refs/tags/libuv/04-test"], cwd=libuv_work)
            self.assertFalse(
                stage_port_repos.local_ref_exists(
                    source_root / "port-libuv",
                    "refs/tags/libuv/04-test",
                )
            )

            config_path = tmp_path / "repositories.yml"
            write_manifest(
                config_path,
                [
                    repository_entry(
                        "libexif",
                        imports=list(inventory.PHASE_1_FROZEN_IMPORTS["libexif"]),
                    ),
                    repository_entry("libuv", imports=["safe/tests"]),
                ],
            )

            remote_map = {
                "safelibs/port-libexif": str(libexif_remote),
                "safelibs/port-libuv": str(libuv_remote),
            }
            git_commands: list[list[str]] = []
            original_run_git = github_auth.run_git

            def logged_run_git(args: list[str], **kwargs: object) -> None:
                git_commands.append(list(args))
                original_run_git(args, **kwargs)

            with mock.patch(
                "tools.github_auth.github_git_url",
                side_effect=lambda github_repo: remote_map[github_repo],
            ), mock.patch(
                "tools.stage_port_repos.github_auth.run_git",
                side_effect=logged_run_git,
            ):
                stage_port_repos.main(
                    [
                        "--config",
                        str(config_path),
                        "--workspace",
                        str(workspace),
                        "--dest-root",
                        str(dest_root),
                        "--source-root",
                        str(source_root),
                    ]
                )

            libuv_fetch_commands = [
                command
                for command in git_commands
                if command[:4] == ["git", "-C", str(dest_root / "libuv"), "fetch"]
            ]
            self.assertEqual(
                libuv_fetch_commands,
                [
                    [
                        "git",
                        "-C",
                        str(dest_root / "libuv"),
                        "fetch",
                        "--no-tags",
                        str(libuv_remote),
                        "refs/tags/libuv/04-test:refs/tags/libuv/04-test",
                    ]
                ],
            )
            self.assertNotIn(
                [
                    "git",
                    "-C",
                    str(dest_root / "libuv"),
                    "fetch",
                    "--tags",
                    "origin",
                ],
                git_commands,
            )
            libuv_origin = run_git(
                ["remote", "get-url", "origin"],
                cwd=dest_root / "libuv",
                capture_output=True,
            ).stdout.strip()
            self.assertEqual(libuv_origin, str(source_root / "port-libuv"))
            self.assertNotEqual(libuv_origin, str(libuv_remote))
            self.assertTrue(
                stage_port_repos.local_ref_exists(dest_root / "libexif", "refs/tags/libexif/04-test")
            )
            self.assertTrue(
                stage_port_repos.local_ref_exists(dest_root / "libuv", "refs/tags/libuv/04-test")
            )
            self.assertTrue((dest_root / "libuv" / "safe" / "debian" / "control").is_file())
            self.assertEqual(
                (
                    workspace
                    / "build-safe"
                    / "libuv"
                    / "source"
                    / "safe"
                    / "target"
                    / "release"
                    / "libuv.a"
                ).read_bytes(),
                b"runtime-support\n",
            )

    def test_stage_from_source_root_materializes_libuv_prebuilt_runtime_archive(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            source_root = tmp_path / "source"
            source_root.mkdir()
            workspace = tmp_path / "workspace"
            dest_root = tmp_path / "staged"

            remote, work = create_remote_repo(tmp_path, "libuv", tag_after_clone=False)
            run_git(["clone", str(remote), str(source_root / "port-libuv")], cwd=tmp_path)
            (
                source_root
                / "port-libuv"
                / "safe"
                / "target"
                / "release"
                / "libuv.a"
            ).parent.mkdir(parents=True, exist_ok=True)
            (
                source_root
                / "port-libuv"
                / "safe"
                / "target"
                / "release"
                / "libuv.a"
            ).write_bytes(b"runtime-support\n")
            (work / "safe" / "target" / "release").mkdir(parents=True, exist_ok=True)
            (work / "safe" / "target" / "release" / "libuv.a").write_bytes(b"tracked-copy\n")

            config_path = tmp_path / "repositories.yml"
            write_manifest(
                config_path,
                [repository_entry("libuv", imports=["safe/prebuilt"])],
            )

            with mock.patch("tools.github_auth.github_git_url", return_value=str(remote)):
                stage_port_repos.main(
                    [
                        "--config",
                        str(config_path),
                        "--workspace",
                        str(workspace),
                        "--dest-root",
                        str(dest_root),
                        "--source-root",
                        str(source_root),
                        "--libraries",
                        "libuv",
                    ]
                )

            self.assertEqual(
                (
                    workspace
                    / "build-safe"
                    / "libuv"
                    / "source"
                    / "safe"
                    / "target"
                    / "release"
                    / "libuv.a"
                ).read_bytes(),
                b"runtime-support\n",
            )

    def test_stage_from_remote_without_source_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            workspace = tmp_path / "workspace"
            dest_root = tmp_path / "staged"
            remote, _ = create_remote_repo(tmp_path, "libdemo", tag_after_clone=False)
            config_path = tmp_path / "repositories.yml"
            write_manifest(
                config_path,
                [repository_entry("libdemo", imports=["safe/tests"])],
            )

            with mock.patch("tools.github_auth.github_git_url", return_value=str(remote)):
                stage_port_repos.main(
                    [
                        "--config",
                        str(config_path),
                        "--workspace",
                        str(workspace),
                        "--dest-root",
                        str(dest_root),
                        "--libraries",
                        "libdemo",
                    ]
                )

            self.assertTrue((dest_root / "libdemo" / "safe" / "tests" / "smoke.txt").is_file())

    def test_stage_from_remote_materializes_libvips_build_check_install(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            workspace = tmp_path / "workspace"
            dest_root = tmp_path / "staged"
            remote, _ = create_libvips_remote_repo(tmp_path)
            config_path = tmp_path / "repositories.yml"
            write_manifest(
                config_path,
                [repository_entry("libvips", imports=["build-check-install"])],
            )

            with mock.patch("tools.github_auth.github_git_url", return_value=str(remote)):
                stage_port_repos.main(
                    [
                        "--config",
                        str(config_path),
                        "--workspace",
                        str(workspace),
                        "--dest-root",
                        str(dest_root),
                        "--libraries",
                        "libvips",
                    ]
                )

            reference_root = dest_root / "libvips" / "build-check-install"
            self.assertEqual(
                (reference_root / "include" / "vips" / "vips.h").read_text(),
                "#define VIPS_VERSION \"8.15.1\"\n",
            )
            self.assertEqual(
                (reference_root / "lib" / "pkgconfig" / "vips.pc").read_text(),
                "prefix=${pcfiledir}/../..\nincludedir=${prefix}/include\nlibdir=${prefix}/lib\n",
            )
            self.assertTrue((reference_root / "lib" / "libvips.so.42.17.1").is_file())
            self.assertTrue((reference_root / "lib" / "libvips-cpp.so.42.17.1").is_file())
            self.assertTrue((reference_root / "lib" / "libvips.so.42").is_symlink())
            self.assertEqual(
                (reference_root / "lib" / "libvips.so.42").readlink().as_posix(),
                "libvips.so.42.17.1",
            )

    def test_stage_fails_when_sibling_repo_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            config_path = tmp_path / "repositories.yml"
            write_manifest(
                config_path,
                [repository_entry("libdemo", imports=["safe/tests"])],
            )

            with self.assertRaisesRegex(ValidatorError, "missing sibling source repo"):
                stage_port_repos.main(
                    [
                        "--config",
                        str(config_path),
                        "--workspace",
                        str(tmp_path / "workspace"),
                        "--dest-root",
                        str(tmp_path / "staged"),
                        "--source-root",
                        str(tmp_path / "source"),
                    ]
                )


if __name__ == "__main__":
    unittest.main()
