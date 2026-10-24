#!/usr/bin/env python3
"""Fix string placeholders in ACTS-produced BO7 .gscc files.

The ACTS compiler emits an "unlinked" form: every string reference slot holds
the sentinel 0x12345678 instead of the real file offset. The string table
records, for each string, which slots belong to it. This tool walks that table
and writes the real offset back into every sentinel slot.

It also performs a minimal sanity check:
  - header field at +8 must match the hash encoded in the file name
  - every export must have a non-zero name_space
  - no 0x12345678 sentinel may remain

Usage
-----
    python fix_gscc.py script_6f294f32b60c71f4.gscc
    python fix_gscc.py --ns namespace_ced633acc59ac526 script_6f294f32b60c71f4.gscc
    python fix_gscc.py --check-only script_6f294f32b60c71f4.gscc

Exit code is 0 on success, 1 if the check fails.
"""

import argparse
import os
import struct
import sys

MAGIC = 0x0A0D4353471A
STRING_PLACEHOLDER = 0x12345678

OFF_STR_COUNT = 0x22
OFF_STR_TABLE = 0x54
OFF_EXPORT_COUNT = 0x18
OFF_EXPORT_TABLE = 0x40
EXPORT_SIZE = 0x28


def fix_string_placeholders(path):
    """Write real string offsets into every 0x12345678 slot.

    Returns the number of slots that were patched.
    """
    with open(path, "rb") as fp:
        data = bytearray(fp.read())

    magic, _ = struct.unpack_from("<QQ", data, 0)
    if magic != MAGIC:
        raise RuntimeError("bad magic: %016x (not an ACTS .gscc?)" % magic)

    str_count = struct.unpack_from("<H", data, OFF_STR_COUNT)[0]
    str_table = struct.unpack_from("<I", data, OFF_STR_TABLE)[0]

    fixed = 0
    pos = str_table
    for _ in range(str_count):
        location, num_address, _typ = struct.unpack_from("<IBB", data, pos)
        for i in range(num_address):
            slot = pos + 8 + 4 * i
            (addr,) = struct.unpack_from("<I", data, slot)
            if addr + 4 <= len(data) and struct.unpack_from("<I", data, addr)[0] == STRING_PLACEHOLDER:
                struct.pack_into("<I", data, addr, location)
                fixed += 1
        pos += 8 + 4 * num_address

    with open(path, "wb") as fp:
        fp.write(data)
    return fixed


def check(path, expect_ns=None):
    """Minimal self-check. Returns True if everything looks right."""
    with open(path, "rb") as fp:
        data = fp.read()

    ok = True

    name = struct.unpack_from("<Q", data, 8)[0]
    base = os.path.basename(path)
    try:
        want = int(base[len("script_"):-len(".gscc")], 16)
    except ValueError:
        want = None
        print("    [!] cannot derive hash from file name: %s" % base)

    if want is not None and name != want:
        print("    [!] header +8 = %016x, file name says %016x" % (name, want))
        ok = False

    exp_count = struct.unpack_from("<H", data, OFF_EXPORT_COUNT)[0]
    exp_table = struct.unpack_from("<I", data, OFF_EXPORT_TABLE)[0]
    for i in range(exp_count):
        o = exp_table + i * EXPORT_SIZE
        _nm, ns = struct.unpack_from("<QQ", data, o)
        if ns == 0:
            print("    [!] export %d has name_space 0 (engine looks up by (ns, name))" % i)
            ok = False
        elif expect_ns is not None and ns != expect_ns:
            print("    [!] export %d name_space = %016x, expected %016x" % (i, ns, expect_ns))
            ok = False

    left = data.count(struct.pack("<I", STRING_PLACEHOLDER))
    if left:
        print("    [!] %d string placeholder(s) still unpatched" % left)
        ok = False

    return ok


def main(argv=None):
    ap = argparse.ArgumentParser(description="Patch and verify an ACTS BO7 .gscc")
    ap.add_argument("gscc", help="path to script_<hash>.gscc")
    ap.add_argument("--ns", default=None,
                    help="expected namespace, e.g. namespace_ced633acc59ac526")
    ap.add_argument("--check-only", action="store_true",
                    help="do not patch, only verify")
    args = ap.parse_args(argv)

    if not os.path.exists(args.gscc):
        print("[abort] not found: %s" % args.gscc)
        return 1

    expect_ns = None
    if args.ns:
        expect_ns = int(args.ns.replace("namespace_", ""), 16)

    if not args.check_only:
        fixed = fix_string_placeholders(args.gscc)
        print("[ok] patched %d string placeholder(s)" % fixed)

    if not check(args.gscc, expect_ns):
        print("[fail] check did not pass")
        return 1

    print("[ok] %s verified" % os.path.basename(args.gscc))
    return 0


if __name__ == "__main__":
    sys.exit(main())
