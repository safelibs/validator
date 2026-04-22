from __future__ import annotations

import unittest
from pathlib import Path


class RepositoryHygieneTests(unittest.TestCase):
    def test_no_stale_source_snapshot_references_remain(self) -> None:
        repo_root = Path(__file__).resolve().parents[1]
        text_suffixes = {".css", ".html", ".js", ".json", ".md", ".py", ".sh", ".txt", ".yaml", ".yml"}
        text_names = {"Dockerfile", "Makefile", "README", "README.md", "repositories.yml", "test.sh"}
        forbidden_terms = ("tagged-port", "source_snapshot", "VALIDATOR_SOURCE_ROOT")
        roots = (
            repo_root / "conftest.py",
            repo_root / "README.md",
            repo_root / "repositories.yml",
            repo_root / "test.sh",
            repo_root / "tests",
            repo_root / "tools",
            repo_root / "unit",
        )
        stale_references: list[str] = []

        for root in roots:
            paths = (root,) if root.is_file() else root.rglob("*")
            for path in paths:
                if path == Path(__file__).resolve():
                    continue
                if not path.is_file() or (path.suffix not in text_suffixes and path.name not in text_names):
                    continue
                text = path.read_text(errors="ignore")
                if any(term in text for term in forbidden_terms):
                    stale_references.append(str(path.relative_to(repo_root)))

        self.assertEqual(stale_references, [])

    def test_no_tagged_port_snapshots_are_checked_in(self) -> None:
        repo_root = Path(__file__).resolve().parents[1]
        snapshot_dirs = sorted(
            path.relative_to(repo_root)
            for path in (repo_root / "tests").glob("*/tests/tagged-port")
            if path.exists()
        )

        self.assertEqual(snapshot_dirs, [])

    def test_no_library_source_files_are_checked_in_at_context_roots(self) -> None:
        repo_root = Path(__file__).resolve().parents[1]
        tests_root = repo_root / "tests"
        forbidden_names = {"CMakeLists.txt", "Makefile", "configure"}
        forbidden_suffixes = {".c", ".cc", ".cpp", ".h", ".hpp"}
        library_source_files = sorted(
            path.relative_to(repo_root)
            for library_root in tests_root.iterdir()
            if library_root.is_dir() and library_root.name != "_shared"
            for path in library_root.iterdir()
            if path.is_file() and (path.name in forbidden_names or path.suffix in forbidden_suffixes)
        )

        self.assertEqual(library_source_files, [])

    def test_port_runs_do_not_substitute_clients_or_commands(self) -> None:
        repo_root = Path(__file__).resolve().parents[1]
        checked_files = (
            repo_root / "tests" / "_shared" / "install_override_debs.sh",
            repo_root / "tests" / "libsdl" / "Dockerfile",
            repo_root / "tests" / "libvips" / "Dockerfile",
            repo_root / "tests" / "libxml" / "Dockerfile",
        )
        forbidden_snippets = {
            repo_root / "tests" / "_shared" / "install_override_debs.sh": (
                "VALIDATOR_VIPS_IMAGE",
                "pygame",
                "vipsthumbnail.real",
                "vipsheader.real",
                "xmllint.real",
            ),
            repo_root / "tests" / "libsdl" / "Dockerfile": (
                "pip3 install",
                "pygame==",
                "PIP_BREAK_SYSTEM_PACKAGES",
            ),
            repo_root / "tests" / "libvips" / "Dockerfile": (
                "/usr/local/bin/vipsheader",
                "vipsheader.real",
            ),
            repo_root / "tests" / "libxml" / "Dockerfile": (
                "/usr/local/bin/xmllint",
            ),
        }
        violations: list[str] = []
        for path in checked_files:
            text = path.read_text(encoding="utf-8")
            for snippet in forbidden_snippets[path]:
                if snippet in text:
                    violations.append(f"{path.relative_to(repo_root)}: {snippet}")

        self.assertEqual(violations, [])


if __name__ == "__main__":
    unittest.main()
