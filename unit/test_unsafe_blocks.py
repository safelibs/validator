from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from textwrap import dedent

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.unsafe_blocks import (
    aggregate_counts,
    analyze_file,
    analyze_safe_dir,
    count_library,
    port_safe_dir,
)


class AnalyzeFileTests(unittest.TestCase):
    def test_classifies_voluntary_block_inside_safe_signature(self) -> None:
        src = dedent(
            """\
            pub fn add(a: u32, b: u32) -> u32 {
                let s = unsafe { std::mem::transmute::<u32, u32>(a) };
                s + b
            }
            """
        )
        counts = analyze_file(src)
        self.assertEqual(counts["total"], 1)
        self.assertEqual(counts["voluntary"], 1)
        self.assertEqual(counts["abi_shaped"], 0)
        self.assertEqual(counts["op_buckets"], {"transmute": 1})

    def test_classifies_abi_shaped_block_inside_extern_or_raw_ptr_fn(self) -> None:
        src = dedent(
            """\
            pub unsafe extern "C" fn ffi(p: *mut u8, n: usize) -> i32 {
                unsafe {
                    *p = 0;
                }
                0
            }
            pub fn from_ptr(p: *const u8) -> u8 {
                unsafe { *p }
            }
            """
        )
        counts = analyze_file(src)
        self.assertEqual(counts["total"], 2)
        self.assertEqual(counts["abi_shaped"], 2)
        self.assertEqual(counts["voluntary"], 0)

    def test_module_level_block_counts_as_voluntary_and_no_enclosing(self) -> None:
        src = dedent(
            """\
            static FOO: u32 = unsafe { 1 };
            """
        )
        counts = analyze_file(src)
        self.assertEqual(counts["total"], 1)
        self.assertEqual(counts["voluntary"], 1)
        self.assertEqual(counts["no_enclosing"], 1)

    def test_does_not_match_inside_string_or_comment(self) -> None:
        src = dedent(
            '''\
            // unsafe { transmute(x) }
            const HINT: &str = "unsafe { transmute(x) }";
            pub fn ok(a: u32) -> u32 { a }
            '''
        )
        counts = analyze_file(src)
        self.assertEqual(counts["total"], 0)
        self.assertEqual(counts["op_buckets"], {})

    def test_static_mut_op_bucket_only_fires_on_real_binding_use(self) -> None:
        src = dedent(
            """\
            static mut COUNTER: u32 = 0;
            pub fn bump() {
                unsafe { COUNTER += 1; }
            }
            pub fn ignored() {
                unsafe { let _ = 42; }
            }
            """
        )
        counts = analyze_file(src)
        self.assertEqual(counts["total"], 2)
        self.assertEqual(counts["op_buckets"].get("static_mut"), 1)
        self.assertEqual(counts["blocks_with_any_op"], 1)


class AnalyzeSafeDirTests(unittest.TestCase):
    def test_aggregates_files_under_safe_and_skips_target(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "src").mkdir()
            (root / "src" / "lib.rs").write_text("pub fn ok(a: u32) -> u32 { unsafe { a } }\n")
            (root / "target" / "debug").mkdir(parents=True)
            (root / "target" / "debug" / "skipme.rs").write_text("unsafe { 1 };\n")
            (root / "src" / "ffi.rs").write_text(
                'pub unsafe extern "C" fn f(p: *mut u8) { unsafe { *p = 0; } }\n'
            )
            counts = analyze_safe_dir(root)
            self.assertEqual(counts["total"], 2)
            self.assertEqual(counts["voluntary"], 1)
            self.assertEqual(counts["abi_shaped"], 1)


class CountLibraryTests(unittest.TestCase):
    def test_returns_none_when_safe_tree_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            self.assertIsNone(count_library(Path(tmp), "missing"))

    def test_resolves_port_dir_layout(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            ports = Path(tmp)
            safe = port_safe_dir(ports, "demo")
            safe.mkdir(parents=True)
            (safe / "lib.rs").write_text("pub fn ok(a: u32) -> u32 { unsafe { a } }\n")
            counts = count_library(ports, "demo")
            self.assertIsNotNone(counts)
            assert counts is not None
            self.assertEqual(counts["total"], 1)
            self.assertEqual(counts["voluntary"], 1)


class AggregateCountsTests(unittest.TestCase):
    def test_sums_across_libraries_and_op_buckets(self) -> None:
        per = {
            "a": {
                "rs_loc": 10,
                "total": 2,
                "abi_shaped": 1,
                "voluntary": 1,
                "no_enclosing": 0,
                "abi_shaped_loc": 3,
                "voluntary_loc": 4,
                "blocks_with_any_op": 1,
                "blocks_voluntary_with_any_op": 1,
                "op_buckets": {"transmute": 1},
            },
            "b": {
                "rs_loc": 20,
                "total": 3,
                "abi_shaped": 0,
                "voluntary": 3,
                "no_enclosing": 1,
                "abi_shaped_loc": 0,
                "voluntary_loc": 9,
                "blocks_with_any_op": 2,
                "blocks_voluntary_with_any_op": 2,
                "op_buckets": {"transmute": 2, "from_raw": 1},
            },
        }
        agg = aggregate_counts(per)
        self.assertEqual(agg["rs_loc"], 30)
        self.assertEqual(agg["total"], 5)
        self.assertEqual(agg["abi_shaped"], 1)
        self.assertEqual(agg["voluntary"], 4)
        self.assertEqual(agg["no_enclosing"], 1)
        self.assertEqual(agg["blocks_with_any_op"], 3)
        self.assertEqual(agg["blocks_voluntary_with_any_op"], 3)
        self.assertEqual(agg["op_buckets"], {"transmute": 3, "from_raw": 1})


if __name__ == "__main__":
    unittest.main()
