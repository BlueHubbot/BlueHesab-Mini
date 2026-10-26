#!/usr/bin/env python3
"""check_data_model_ddl - run the SQL in docs/architecture/DATA_MODEL.md on a real SQLite and prove
that its CHECK, FOREIGN KEY and UNIQUE constraints behave as the data contract says.

Usage:  python3 tool/docs_check/check_data_model_ddl.py
Exit code 1 if the SQL does not run or any expectation fails.
Standard library only. In-memory database. Read-only: never modifies files.

What it proves: DD-02 (money is canonical decimal TEXT, 18 digits at most, a sign only for opening
balances), the shape of transfers (one row, two different accounts, no category), budget scope,
capture hints (last 2-4 digits only), unique active names, foreign keys.
What it does not prove: rules that live above SQL (a transaction's currency equals its account's,
I-04; balances, I-07; and so on). Those need application code and tests.
"""
import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODEL = ROOT / "docs/architecture/DATA_MODEL.md"
NOW = "2026-10-24T06:55:00.000Z"
DAY = "2026-10-24"

# Non-ASCII digits are built from code points so this file stays free of hidden or look-alike characters.
ARABIC_INDIC_THREE = chr(0x0663)
PERSIAN_FOUR = chr(0x06F4)

checked = 0
failures = []
_counter = 0


def new_id():
    global _counter
    _counter += 1
    return f"id{_counter:05d}"


def accepted(conn, sql, params):
    """True if the statement runs, False on a constraint violation. Other SQL errors propagate."""
    try:
        conn.execute(sql, params)
        return True
    except sqlite3.IntegrityError:
        return False


def expect(conn, label, sql, params, should_accept):
    global checked
    checked += 1
    got = accepted(conn, sql, params)
    if got != should_accept:
        want = "accepted" if should_accept else "rejected"
        failures.append(f"FAIL {label}: expected {want}, got {'accepted' if got else 'rejected'}")


TX = ("INSERT INTO transactions (id,kind,amount_minor,currency,account_id,to_account_id,category_id,"
      "occurred_on,created_at,updated_at,origin) VALUES (?,?,?,?,?,?,?,?,?,?,?)")


def tx(kind="expense", amount="100", account="a1", to=None, category=None, origin="manual"):
    return (new_id(), kind, amount, "IRR", account, to, category, DAY, NOW, NOW, origin)


ACC = ("INSERT INTO accounts (id,name,name_norm,kind,currency,opening_balance_minor,created_at,updated_at) "
       "VALUES (?,?,?,?,?,?,?,?)")


def acc(opening="0", name=None, kind="cash", currency="IRR"):
    i = new_id()
    n = name or i
    return (i, n, n, kind, currency, opening, NOW, NOW)


CAT = ("INSERT INTO categories (id,kind,name,name_norm,icon_id,created_at,updated_at) "
       "VALUES (?,?,?,?,?,?,?)")


def cat(kind="expense", name=None):
    i = new_id()
    n = name or i
    return (i, kind, n, n, "icon", NOW, NOW)


BUD = ("INSERT INTO m_budget_limits (id,scope,category_id,currency,limit_minor,calendar,valid_from,created_at) "
       "VALUES (?,?,?,?,?,?,?,?)")


def bud(scope="overall", category=None, limit="1000", calendar="jalali"):
    return (new_id(), scope, category, "IRR", limit, calendar, DAY, NOW)


HINT = "INSERT INTO account_hints (id,account_id,bank_id,last_digits,created_at) VALUES (?,?,?,?,?)"


def load_sql():
    text = MODEL.read_text(encoding="utf-8")
    blocks = re.findall(r"```sql\n(.*?)\n```", text, re.S)
    if not blocks:
        raise SystemExit("FAIL ddl: no ```sql block found in docs/architecture/DATA_MODEL.md")
    return "\n".join(blocks)


def main():
    conn = sqlite3.connect(":memory:", isolation_level=None)
    try:
        conn.executescript(load_sql())
    except sqlite3.Error as exc:
        print(f"FAIL ddl: the SQL in DATA_MODEL.md does not run on SQLite {sqlite3.sqlite_version}: {exc}")
        return 1
    if conn.execute("PRAGMA foreign_keys").fetchone()[0] != 1:
        print("FAIL ddl: the SQL must switch foreign keys on (PRAGMA foreign_keys = ON)")
        return 1

    conn.executemany("INSERT INTO currencies (code,minor_digits) VALUES (?,?)", [("IRR", 0), ("USD", 2)])
    conn.execute(ACC, ("a1", "Cash", "cash", "cash", "IRR", "0", NOW, NOW))
    conn.execute(ACC, ("a2", "Bank", "bank", "bank", "IRR", "0", NOW, NOW))
    conn.execute(CAT, ("c1", "expense", "Food", "food", "icon", NOW, NOW))
    conn.execute(CAT, ("c2", "income", "Salary", "salary", "icon", NOW, NOW))

    # DD-02: transaction amounts are canonical positive decimal text, 18 digits at most.
    nines18 = "9" * 18
    for v in ("1", "100", "123456789012345678", nines18):
        expect(conn, f"amount_minor {v!r}", TX, tx(amount=v), True)
    bad_amounts = ["0", "01", "-5", "+5", "", "1.5", "1e3", " 1", "1 ", "1\n", "1" + "0" * 18, "9" * 19,
                   ARABIC_INDIC_THREE, "1" + PERSIAN_FOUR]
    for v in bad_amounts:
        expect(conn, f"amount_minor {v!r} must be rejected", TX, tx(amount=v), False)

    # DD-02: opening balances may be 0 or negative, never padded, never longer than 18 digits.
    for v in ("0", "5", "-5", nines18, "-" + nines18):
        expect(conn, f"opening_balance_minor {v!r}", ACC, acc(opening=v), True)
    bad_openings = ["00", "-0", "+5", "05", "-05", "", "-", "--5", "1.5", "-1.5", " 5", "5 ",
                    "9" * 19, "-" + "9" * 19, ARABIC_INDIC_THREE]
    for v in bad_openings:
        expect(conn, f"opening_balance_minor {v!r} must be rejected", ACC, acc(opening=v), False)

    # Transfers are one row with two different accounts and no category (DD-07, I-03).
    expect(conn, "transfer a1 -> a2", TX, tx(kind="transfer", to="a2"), True)
    expect(conn, "transfer without destination must be rejected", TX, tx(kind="transfer"), False)
    expect(conn, "expense with a destination must be rejected", TX, tx(kind="expense", to="a2"), False)
    expect(conn, "transfer to the same account must be rejected", TX, tx(kind="transfer", to="a1"), False)
    expect(conn, "transfer with a category must be rejected", TX, tx(kind="transfer", to="a2", category="c1"), False)
    expect(conn, "expense with a category", TX, tx(category="c1"), True)
    expect(conn, "unknown kind must be rejected", TX, tx(kind="refund"), False)
    expect(conn, "unknown origin must be rejected", TX, tx(origin="telegram"), False)
    expect(conn, "origin sms", TX, tx(origin="sms"), True)
    expect(conn, "unknown account must be rejected (foreign key)", TX, tx(account="nope"), False)
    expect(conn, "unknown category must be rejected (foreign key)", TX, tx(category="nope"), False)

    # Budget limits (DD-09): scope decides whether a category is required; same money pattern.
    expect(conn, "overall limit", BUD, bud(), True)
    expect(conn, "category limit", BUD, bud(scope="category", category="c1"), True)
    expect(conn, "category limit without category must be rejected", BUD, bud(scope="category"), False)
    expect(conn, "overall limit with a category must be rejected", BUD, bud(scope="overall", category="c1"), False)
    expect(conn, "limit 0 must be rejected", BUD, bud(limit="0"), False)
    expect(conn, "limit with 19 digits must be rejected", BUD, bud(limit="9" * 19), False)
    expect(conn, "unknown calendar must be rejected", BUD, bud(calendar="hijri"), False)

    # Capture hints keep at most the last four digits (DATA_MODEL 5a).
    for v in ("12", "123", "1234", None):
        expect(conn, f"last_digits {v!r}", HINT, (new_id(), "a1", None, v, NOW), True)
    for v in ("1", "12345", "12a4", ""):
        expect(conn, f"last_digits {v!r} must be rejected", HINT, (new_id(), "a1", None, v, NOW), False)

    # Learned merchant map must point at a real category.
    expect(conn, "merchant map with a real category",
           "INSERT INTO capture_merchant_map (merchant_norm,category_id,uses,updated_at) VALUES (?,?,?,?)",
           ("shop", "c1", 1, NOW), True)
    expect(conn, "merchant map with an unknown category must be rejected",
           "INSERT INTO capture_merchant_map (merchant_norm,category_id,uses,updated_at) VALUES (?,?,?,?)",
           ("shop2", "nope", 1, NOW), False)

    # Unique active names: QX-21 for accounts, one active name per kind for categories.
    expect(conn, "first account named dup", ACC, acc(name="dup"), True)
    expect(conn, "second active account named dup must be rejected", ACC, acc(name="dup"), False)
    conn.execute("UPDATE accounts SET archived_at = ? WHERE name_norm = 'dup'", (NOW,))
    expect(conn, "account named dup after the first is archived", ACC, acc(name="dup"), True)
    expect(conn, "first expense category named same", CAT, cat(kind="expense", name="same"), True)
    expect(conn, "second active expense category named same must be rejected", CAT, cat(kind="expense", name="same"), False)
    expect(conn, "income category named same (other kind)", CAT, cat(kind="income", name="same"), True)

    checked_extra = 0
    if conn.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
        failures.append("FAIL integrity_check is not ok")
    checked_extra += 1
    if conn.execute("PRAGMA foreign_key_check").fetchall():
        failures.append("FAIL foreign_key_check reports violations")
    checked_extra += 1

    total = checked + checked_extra
    for line in failures:
        print(line)
    print(f"check_data_model_ddl: SQLite {sqlite3.sqlite_version}; {total} expectation(s) checked, {len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
