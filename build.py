#!/usr/bin/env python3
"""One-shot build script for the BO7 ZM menu.

What it does:
  1. compile scripts/bo7_zm_menu.gsc with the ACTS compiler
  2. patch string placeholders (see fix_gscc.py)
  3. verify the header hash, namespace and remaining sentinels
  4. copy the finished .gscc into the injection directory

Usage
-----
    python build.py
    python build.py --cli acts
    python build.py --out "D:\\cod25\\saturn\\Assets\\Scripts"
    python build.py --no-copy

The default compiler command is `acts`, which must be on PATH. If your ACTS
install uses a different launcher, pass it with --cli.
"""

import argparse
import os
import shutil
import subprocess
import sys

import fix_gscc

HERE = os.path.dirname(os.path.abspath(__file__))

# Injection target. The script replaces scripts/mp/playercards.gsc, whose
# asset path hashes to 6F294F32B60C71F4. Namespace is declared in the source.
SCRIPT_HASH = "6f294f32b60c71f4"
NAMESPACE = "namespace_ced633acc59ac526"
SOURCE = os.path.join(HERE, "scripts", "bo7_zm_menu.gsc")
DEFAULT_OUT = r"D:\cod25\saturn\Assets\Scripts"


def main(argv=None):
    ap = argparse.ArgumentParser(description="Build the BO7 ZM menu .gscc")
    ap.add_argument("--cli", default="acts", help="ACTS launcher (default: acts on PATH)")
    ap.add_argument("--out", default=DEFAULT_OUT, help="injection directory")
    ap.add_argument("--stage", default=os.path.join(HERE, "build"), help="local staging directory")
    ap.add_argument("--no-copy", action="store_true", help="build only, do not copy")
    args = ap.parse_args(argv)

    if not os.path.exists(SOURCE):
        print("[abort] source not found: %s" % SOURCE)
        return 1

    os.makedirs(args.stage, exist_ok=True)
    name = "script_" + SCRIPT_HASH
    out_base = os.path.join(args.stage, name)

    cmd = [args.cli, "gscc", "-g", "bo7", "-p", "pc", "--name", name, "-o", out_base, SOURCE]
    print("[build] %s" % " ".join(cmd))
    try:
        rc = subprocess.run(cmd).returncode
    except FileNotFoundError:
        print("[abort] compiler not found: %s" % args.cli)
        print("        pass --cli <path to acts> or add it to PATH")
        return 1

    if rc != 0:
        print("[abort] compile failed (exit %d)" % rc)
        return 1

    gscc = out_base + ".gscc"
    if not os.path.exists(gscc):
        print("[abort] compiler produced no %s" % gscc)
        return 1

    fixed = fix_gscc.fix_string_placeholders(gscc)
    print("[patch] %d string placeholder(s)" % fixed)

    expect_ns = int(NAMESPACE.replace("namespace_", ""), 16)
    if not fix_gscc.check(gscc, expect_ns):
        print("[abort] verification failed, injection directory untouched")
        return 1

    print("[ok] %s" % gscc)

    if args.no_copy:
        return 0

    os.makedirs(args.out, exist_ok=True)
    dst = os.path.join(args.out, name + ".gscc")
    shutil.copy2(gscc, dst)
    print("[done] copied to %s" % dst)
    return 0


if __name__ == "__main__":
    sys.exit(main())
