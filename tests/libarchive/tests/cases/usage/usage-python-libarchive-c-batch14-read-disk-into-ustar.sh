#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-read-disk-into-ustar
# @title: python-libarchive-c read_disk feed into ustar archive via ctypes
# @description: Stages a small directory tree on disk, opens an archive_read_disk handle through ctypes against libarchive.so.13 (libarchive_c 2.9 does not wrap the read_disk API), walks each filesystem path with archive_read_disk_open / archive_read_next_header2 / archive_read_disk_descend, and feeds every visited entry into a python-libarchive-c file_writer in the ustar variant. The resulting archive is read back and verified to contain every staged path with its original payload bytes.
# @timeout: 240
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-read-disk-into-ustar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stage="$tmpdir/stage"
mkdir -p "$stage/dir1/dir2"
printf 'top-level payload\n' >"$stage/top.txt"
printf 'first nested payload\n' >"$stage/dir1/inner.txt"
printf 'second nested payload bytes\n' >"$stage/dir1/dir2/leaf.txt"

python3 - <<'PY' "$case_id" "$tmpdir" "$stage"
import ctypes
import os
import sys
from pathlib import Path

import libarchive
from libarchive.ffi import (
    write_data,
    write_finish_entry,
    write_header,
)

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])
stage = Path(sys.argv[3])

# archive_read_disk_* live in libarchive but are not wrapped by 2.9.
so = ctypes.CDLL("libarchive.so.13")
read_disk_new = so.archive_read_disk_new
read_disk_new.argtypes = []
read_disk_new.restype = ctypes.c_void_p
read_disk_open = so.archive_read_disk_open
read_disk_open.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
read_disk_open.restype = ctypes.c_int
read_disk_descend = so.archive_read_disk_descend
read_disk_descend.argtypes = [ctypes.c_void_p]
read_disk_descend.restype = ctypes.c_int
read_next_header2 = so.archive_read_next_header2
read_next_header2.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
read_next_header2.restype = ctypes.c_int
read_free = so.archive_read_free
read_free.argtypes = [ctypes.c_void_p]
read_free.restype = ctypes.c_int
entry_new = so.archive_entry_new
entry_new.argtypes = []
entry_new.restype = ctypes.c_void_p
entry_free = so.archive_entry_free
entry_free.argtypes = [ctypes.c_void_p]
entry_free.restype = None
entry_pathname = so.archive_entry_pathname
entry_pathname.argtypes = [ctypes.c_void_p]
entry_pathname.restype = ctypes.c_char_p
entry_set_pathname = so.archive_entry_set_pathname
entry_set_pathname.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
entry_set_pathname.restype = None
entry_size = so.archive_entry_size
entry_size.argtypes = [ctypes.c_void_p]
entry_size.restype = ctypes.c_int64
entry_filetype = so.archive_entry_filetype
entry_filetype.argtypes = [ctypes.c_void_p]
entry_filetype.restype = ctypes.c_uint

ARCHIVE_OK = 0
ARCHIVE_EOF = 1
ARCHIVE_RETRY = 10
ARCHIVE_WARN = -20
S_IFREG = 0o100000
S_IFDIR = 0o040000

archive_path = tmpdir / "fromdisk.tar"
prev = Path.cwd()
os.chdir(stage)
try:
    rd = read_disk_new()
    assert rd, "archive_read_disk_new failed"
    rc = read_disk_open(rd, b".")
    assert rc == ARCHIVE_OK, rc

    with libarchive.file_writer(str(archive_path), "ustar") as writer:
        archive_p = writer._pointer
        ent = entry_new()
        try:
            while True:
                rc = read_next_header2(rd, ent)
                if rc == ARCHIVE_EOF:
                    break
                if rc not in (ARCHIVE_OK, ARCHIVE_WARN):
                    raise RuntimeError(f"read_next_header2 rc={rc}")

                pn = entry_pathname(ent)
                # Strip a leading "./" so the archive paths match what
                # the readback assertions expect.
                if pn.startswith(b"./"):
                    entry_set_pathname(ent, pn[2:])

                ftype = entry_filetype(ent) & 0o170000
                size = entry_size(ent)
                write_header(archive_p, ent)
                if ftype == S_IFREG and size > 0:
                    src = (stage / pn.decode("utf-8")).resolve()
                    data = src.read_bytes()
                    write_data(archive_p, data, len(data))
                write_finish_entry(archive_p)

                read_disk_descend(rd)
        finally:
            entry_free(ent)
            read_free(rd)
finally:
    os.chdir(prev)

# Read back and verify.
expected = {
    "top.txt": (stage / "top.txt").read_bytes(),
    "dir1/inner.txt": (stage / "dir1/inner.txt").read_bytes(),
    "dir1/dir2/leaf.txt": (stage / "dir1/dir2/leaf.txt").read_bytes(),
}

got = {}
with libarchive.file_reader(str(archive_path)) as archive:
    for entry in archive:
        name = entry.pathname.rstrip("/")
        # Skip pure-dir entries (we kept them in the archive but only
        # care that regular files round-tripped).
        data = b"".join(entry.get_blocks())
        if entry.isreg:
            got[name] = data

for name, payload in expected.items():
    assert name in got, (name, sorted(got))
    assert got[name] == payload, (name, len(got[name]), len(payload))
print("read-disk-ustar", len(got))
PY
