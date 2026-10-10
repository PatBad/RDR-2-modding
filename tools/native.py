#!/usr/bin/env python3
"""Look up RDR2 natives in data/natives.json.

Examples:
    python tools/native.py SET_ENTITY_INVINCIBLE      exact name, or part of a name
    python tools/native.py 0xA5C38736C426FCB8         by hash
    python tools/native.py invincible -c              also search the documentation comments
    python tools/native.py core -n ATTRIBUTE          only one namespace
"""

import argparse
import json
import sys
from pathlib import Path

JSON_PATH = Path(__file__).resolve().parent.parent / "data" / "natives.json"


def signature(ns, hash_, n):
    params = ", ".join("..." if p["name"] == "..." else f"{p['type']} {p['name']}" for p in n["params"])
    return f"{n['return_type']} {ns}::{n['name']}({params})  [{hash_}]"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("query", help="native name, part of a name, or hash")
    ap.add_argument("-c", "--comments", action="store_true", help="also match documentation comments")
    ap.add_argument("-n", "--namespace", help="limit to one namespace, e.g. PLAYER")
    ap.add_argument("-l", "--limit", type=int, default=40, help="max results (default 40)")
    args = ap.parse_args()

    # Windows consoles default to a legacy code page; comments contain non-ASCII text.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    natives = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    query = args.query.strip()
    q = query.upper()
    entries = [
        (ns, h, n)
        for ns, block in natives.items()
        if not args.namespace or ns == args.namespace.upper()
        for h, n in block.items()
    ]

    if q.startswith("0X"):
        matches = [e for e in entries if e[1].upper() == q or e[2].get("gta_hash", "").upper() == q]
    else:
        exact = [e for e in entries if e[2]["name"] == q]
        matches = exact or [e for e in entries if q in e[2]["name"]]
        if args.comments:
            seen = {e[1] for e in matches}
            matches += [e for e in entries if e[1] not in seen and query.lower() in e[2]["comment"].lower()]

    if not matches:
        print(f"No natives match {query!r}. Try a shorter part of the name, or -c to search comments.")
        return 1

    full = len(matches) <= 5
    for ns, h, n in matches[: args.limit]:
        print(signature(ns, h, n))
        comment = n["comment"].strip()
        if comment:
            lines = comment.splitlines() if full else comment.splitlines()[:1]
            for line in lines:
                print(f"    {line}")
        if n.get("unused"):
            print("    [Unused by the game's own scripts; may not work.]")
        if full:
            print()
    if len(matches) > args.limit:
        print(f"... {len(matches) - args.limit} more; narrow the query or raise --limit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
