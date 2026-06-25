"""SQL Server connection helper for hanging_data_new."""
from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Any, Iterable

import pyodbc

SERVER = os.environ.get("HANGING_SQL_SERVER", r".\SQLEXPRESS")
DATABASE = os.environ.get("HANGING_SQL_DB", "hanging_data_new")
DRIVER = os.environ.get("HANGING_SQL_DRIVER", "ODBC Driver 17 for SQL Server")

_CONN_STR = (
    f"DRIVER={{{DRIVER}}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)


@contextmanager
def get_conn():
    conn = pyodbc.connect(_CONN_STR, autocommit=True)
    try:
        yield conn
    finally:
        conn.close()


def query(sql: str, params: Iterable[Any] | None = None) -> list[dict]:
    """Run a parameterised query and return list of dict rows."""
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(sql, tuple(params) if params else ())
        cols = [c[0] for c in cur.description] if cur.description else []
        rows = [dict(zip(cols, r)) for r in cur.fetchall()]
        return rows


def ping() -> dict:
    try:
        rows = query("SELECT @@SERVERNAME AS server, DB_NAME() AS db, GETDATE() AS now")
        return {"ok": True, **rows[0]}
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": str(exc)}
