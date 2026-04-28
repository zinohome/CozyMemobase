"""Wait for PostgreSQL to be fully ready before starting Memobase.

Uses psycopg2 (same driver as Memobase) for consistent auth behavior.
"""
import os
import sys
import time


def wait():
    import psycopg2

    db_url = os.environ.get("DATABASE_URL", "")
    max_retries = 60
    delay = 3
    consecutive_ok = 0
    required_ok = 5

    for i in range(1, max_retries + 1):
        try:
            conn = psycopg2.connect(db_url, connect_timeout=5)
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
            conn.close()
            consecutive_ok += 1
            if consecutive_ok >= required_ok:
                print(f"[wait_for_pg] PostgreSQL stable after {i * delay}s ({required_ok} consecutive checks)")
                return True
        except Exception:
            consecutive_ok = 0
            if i == max_retries:
                print(f"[wait_for_pg] FAILED after {max_retries * delay}s", file=sys.stderr)
                return False
        time.sleep(delay)
    return False


if __name__ == "__main__":
    if not wait():
        sys.exit(1)
