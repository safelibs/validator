from __future__ import annotations

import io
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError
from tools.fetch_port_sources import (
    _extract_safe_subtree,
    _safe_relative_path,
    load_lock_libraries,
)


def _make_tarball(entries: list[tuple[str, bytes | None]]) -> bytes:
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        for name, payload in entries:
            if payload is None:
                info = tarfile.TarInfo(name=name)
                info.type = tarfile.DIRTYPE
                tar.addfile(info)
            else:
                info = tarfile.TarInfo(name=name)
                info.size = len(payload)
                tar.addfile(info, io.BytesIO(payload))
    return buf.getvalue()


class SafeRelativePathTests(unittest.TestCase):
    def test_returns_path_under_safe(self) -> None:
        self.assertEqual(_safe_relative_path("port-cjson-abc/safe/lib.rs"), "lib.rs")
        self.assertEqual(_safe_relative_path("port-cjson-abc/safe/src/main.rs"), "src/main.rs")

    def test_skips_entries_outside_safe(self) -> None:
        self.assertIsNone(_safe_relative_path("port-cjson-abc/Cargo.toml"))
        self.assertIsNone(_safe_relative_path("port-cjson-abc/safe"))
        self.assertIsNone(_safe_relative_path("port-cjson-abc/safe/"))

    def test_rejects_traversal(self) -> None:
        with self.assertRaises(ValidatorError):
            _safe_relative_path("port-cjson-abc/safe/../escape.rs")


class ExtractSafeSubtreeTests(unittest.TestCase):
    def test_extracts_only_safe_entries(self) -> None:
        tarball = _make_tarball(
            [
                ("port-demo-aaaa/Cargo.toml", b"workspace"),
                ("port-demo-aaaa/safe", None),
                ("port-demo-aaaa/safe/lib.rs", b"pub fn x() {}\n"),
                ("port-demo-aaaa/safe/src/", None),
                ("port-demo-aaaa/safe/src/main.rs", b"fn main() {}\n"),
                ("port-demo-aaaa/abi/skip.rs", b"// skipped"),
            ]
        )
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "out"
            extracted = _extract_safe_subtree(tarball, target=target)
            self.assertEqual(extracted, 2)
            self.assertTrue((target / "lib.rs").is_file())
            self.assertTrue((target / "src" / "main.rs").is_file())
            self.assertFalse((target / "Cargo.toml").exists())
            self.assertFalse((target.parent / "abi").exists())

    def test_raises_when_no_safe_entries(self) -> None:
        tarball = _make_tarball([("port-demo/Cargo.toml", b"workspace")])
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "out"
            with self.assertRaises(ValidatorError):
                _extract_safe_subtree(tarball, target=target)

    def test_replaces_existing_target(self) -> None:
        tarball = _make_tarball(
            [
                ("port-demo/safe/lib.rs", b"pub fn x() {}\n"),
            ]
        )
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "out"
            target.mkdir()
            (target / "stale.rs").write_text("stale")
            _extract_safe_subtree(tarball, target=target)
            self.assertFalse((target / "stale.rs").exists())
            self.assertTrue((target / "lib.rs").is_file())


class LoadLockLibrariesTests(unittest.TestCase):
    def test_returns_library_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            lock = Path(tmp) / "lock.json"
            lock.write_text(
                """{
                  "schema_version": 1,
                  "libraries": [
                    {"library": "cjson", "repository": "safelibs/port-cjson", "commit": "deadbeef"}
                  ]
                }"""
            )
            entries = load_lock_libraries(lock)
            self.assertEqual(len(entries), 1)
            self.assertEqual(entries[0]["library"], "cjson")

    def test_rejects_missing_file(self) -> None:
        with self.assertRaises(ValidatorError):
            load_lock_libraries(Path("/nope/missing.json"))

    def test_rejects_non_object_payload(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            lock = Path(tmp) / "lock.json"
            lock.write_text("[1, 2, 3]")
            with self.assertRaises(ValidatorError):
                load_lock_libraries(lock)


if __name__ == "__main__":
    unittest.main()
