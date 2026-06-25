"""Smoke-test connection + CREATE app database (KHONG apply migrations).

Dung khi muon kiem tra cau hinh `.env` ket noi duoc den SQL Server va MES DB,
truoc khi chay full migration.

Usage (tu project root):
    .venv\\Scripts\\python.exe scripts\\create_app_db.py

Hoac qua run.ps1:
    .\\run.ps1 -CreateDb
"""
from __future__ import annotations

import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT))

from app import db  # noqa: E402  — triggers .env load
from scripts.apply_migrations import ensure_app_db_exists  # noqa: E402


def main() -> int:
    print(f"Server : {db.SERVER}")
    print(f"App DB : {db.APP_DB}")
    print(f"MES DB : {db.MES_DB}")
    print(f"Driver : {db.DRIVER}")
    print()

    if db.APP_DB.strip().lower() == db.MES_DB.strip().lower():
        print(
            f"ERROR: HANGING_APP_DB == HANGING_MES_DB ('{db.APP_DB}'). "
            f"App DB phai khac MES DB.",
            file=sys.stderr,
        )
        return 2

    try:
        ensure_app_db_exists()
    except Exception as exc:
        print(f"\nFAILED: {exc}", file=sys.stderr)
        print(
            "\nKiem tra:\n"
            "  - HANGING_SQL_SERVER co dung khong (nslookup / SSMS connect duoc?)\n"
            "  - HANGING_MES_DB ton tai tren server do khong\n"
            "  - Account Windows co quyen 'CREATE DATABASE' khong",
            file=sys.stderr,
        )
        return 2

    print("\nOK. Lan dau con phai chay migration:")
    print("    .\\run.ps1 -Migrate")
    return 0


if __name__ == "__main__":
    sys.exit(main())
