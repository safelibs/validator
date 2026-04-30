#!/usr/bin/env bash
# @testcase: usage-python-libarchive-c-batch14-pax-extended-attributes
# @title: python-libarchive-c pax extended attributes round trip
# @description: Writes a pax archive whose entries carry user-namespace extended attributes set via archive_entry_xattr_add_entry (libarchive_c 2.9 does not wrap xattr APIs, so they are pulled from libarchive.so.13 with ctypes). Reads the archive back and walks the xattrs through archive_entry_xattr_reset / archive_entry_xattr_next, asserting both the names and values survive the pax round trip.
# @timeout: 180
# @tags: usage, archive, python
# @client: python3-libarchive-c

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python-libarchive-c-batch14-pax-extended-attributes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import ctypes
import sys
from pathlib import Path

import libarchive
from libarchive.entry import ArchiveEntry, new_archive_entry
from libarchive.ffi import (
    REGULAR_FILE,
    entry_set_filetype,
    entry_set_perm,
    entry_set_size,
    write_data,
    write_finish_entry,
    write_header,
)

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

so = ctypes.CDLL("libarchive.so.13")
xattr_add = so.archive_entry_xattr_add_entry
xattr_add.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_size_t]
xattr_add.restype = None
xattr_clear = so.archive_entry_xattr_clear
xattr_clear.argtypes = [ctypes.c_void_p]
xattr_clear.restype = None
xattr_reset = so.archive_entry_xattr_reset
xattr_reset.argtypes = [ctypes.c_void_p]
xattr_reset.restype = ctypes.c_int
xattr_next = so.archive_entry_xattr_next
xattr_next.argtypes = [
    ctypes.c_void_p,
    ctypes.POINTER(ctypes.c_char_p),
    ctypes.POINTER(ctypes.c_void_p),
    ctypes.POINTER(ctypes.c_size_t),
]
xattr_next.restype = ctypes.c_int

attrs_per_file = {
    "first.txt": [(b"user.color", b"red"), (b"user.tag", b"alpha")],
    "second.txt": [(b"user.role", b"data\0with\0nul")],
}
payloads = {
    "first.txt": b"first payload\n",
    "second.txt": b"second payload bytes\n",
}

path = tmpdir / "xattr.pax"
with libarchive.file_writer(str(path), "pax") as writer:
    archive_p = writer._pointer
    for name, payload in payloads.items():
        with new_archive_entry() as ent:
            ArchiveEntry(None, ent).pathname = name
            entry_set_filetype(ent, REGULAR_FILE)
            entry_set_perm(ent, 0o644)
            entry_set_size(ent, len(payload))
            xattr_clear(ent)
            for key, val in attrs_per_file[name]:
                buf = ctypes.create_string_buffer(val, len(val))
                xattr_add(ent, key, ctypes.cast(buf, ctypes.c_void_p), len(val))
            write_header(archive_p, ent)
            write_data(archive_p, payload, len(payload))
            write_finish_entry(archive_p)

# Now read back and walk xattrs from each entry.
seen = {}
seen_payloads = {}
with libarchive.file_reader(str(path)) as archive:
    for entry in archive:
        ent_p = entry._entry_p
        xattr_reset(ent_p)
        items = []
        name_p = ctypes.c_char_p()
        val_p = ctypes.c_void_p()
        size = ctypes.c_size_t()
        while True:
            rc = xattr_next(ent_p, ctypes.byref(name_p), ctypes.byref(val_p), ctypes.byref(size))
            if rc != 0:
                break
            value_bytes = ctypes.string_at(val_p, size.value) if val_p.value else b""
            items.append((name_p.value, value_bytes))
        # libarchive's pax reader exposes both the SCHILY.xattr.* and
        # LIBARCHIVE.xattr.* records as separate xattr entries on the same
        # archive_entry, so the iterator yields each (name, value) twice.
        # Deduplicate while preserving insertion order before comparing.
        deduped = []
        seen_keys = set()
        for key, val in items:
            if (key, val) in seen_keys:
                continue
            seen_keys.add((key, val))
            deduped.append((key, val))
        seen[entry.pathname] = deduped
        seen_payloads[entry.pathname] = b"".join(entry.get_blocks())

assert seen_payloads == payloads, sorted(seen_payloads.keys())
for name, expected in attrs_per_file.items():
    got = seen[name]
    assert got == expected, (name, got, expected)
print("pax-xattrs", {k: len(v) for k, v in seen.items()})
PY
