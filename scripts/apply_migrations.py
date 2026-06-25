"""Apply all SQL migrations in app/migrations/ to the configured DB.

Usage (from project root):
    .venv/Scripts/python.exe scripts/apply_migrations.py

Or via run.ps1:
    .\run.ps1 -Migrate

All migration files MUST be idempotent (use IF NOT EXISTS guards) — script just
runs them in lexical order. Splits each file on lines containing only `GO`
because pyodbc doesn't understand the sqlcmd batch separator.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT))

from app import db  # noqa: E402  — triggers .env load

GO_RE = re.compile(r"^\s*GO\s*(?:--.*)?$", re.IGNORECASE | re.MULTILINE)
MIG_DIR = PROJECT / "app" / "migrations"


def main() -> int:
    files = sorted(MIG_DIR.glob("*.sql"))
    if not files:
        print(f"No migrations found in {MIG_DIR}")
        return 1

    print(f"Target: server={db.SERVER}  db={db.DATABASE}")
    print(f"Applying {len(files)} migrations from {MIG_DIR}\n")

    with db.get_conn() as conn:
        cur = conn.cursor()
        for f in files:
            print(f"  {f.name}")
            sql = f.read_text(encoding="utf-8")
            batches = [b.strip() for b in GO_RE.split(sql) if b.strip()]
            for i, batch in enumerate(batches, 1):
                try:
                    cur.execute(batch)
                    while cur.nextset():
                        pass
                except Exception as exc:
                    print(f"    batch {i} FAILED: {exc}", file=sys.stderr)
                    print("    --- batch preview ---", file=sys.stderr)
                    print(batch[:400], file=sys.stderr)
                    return 2

    print("\nAll migrations applied.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
