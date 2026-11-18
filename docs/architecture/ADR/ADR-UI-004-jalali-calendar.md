# ADR-UI-004: Jalali calendar — in-house integer arithmetic behind the central date-layer port
- **Status:** PROPOSED (drafted 2026-11-17 in T-036; the product owner accepts or rejects, AUTONOMY_AND_ESCALATION §4; ADRX-04 names the owner as acceptor)
- **Date:** 2026-11-17
- **Owner:** Architect (drafted for Product/Contracts, Agent 1, who owns the spec row)
- **Approver:** Product owner

## Context (زمینه)
The UI spec keeps all Jalali arithmetic (conversion, leap years, month length, month addition) in one central date layer (DT-05) and stores only Gregorian `yyyy-MM-dd` dates and UTC instants (DT-01). Table 12-1-الف lists ADR-UI-004 "Jalali calendar library" with the default «هیچ کتابخانه‌ای؛ محاسبه فقط در لایه‌ی تاریخ مرکزی» and the separating layer "central date layer and `CalendarGridPort`"; ADRX-04 is its acceptance rule; RKX-05 is the risk "the library fails the vectors".
The M0 spike (SP-04, T-004) built one port, `JalaliCalendarPort`, with two implementations and tested both. Its findings are the input to this ADR (`spike/T-004-jalali/README.md` F1–F7; `docs/architecture/SPIKE_REPORT.md` §1 row SP-04, §4 #3).

## Decision drivers
- Correct on every DT-05 vector and on both calendars of DT-02 (ADRX-04).
- Exact on every target, including the web demo (no floating point).
- Fewer runtime dependencies (OPEN_SOURCE_AUDIT, CB-9) and a licence that is simple to honour.
- Reversible: callers depend on the port only, never on an implementation.
- Spec rules (clamped month addition, validity) written once, in the layer, not in a library.

## Options (گزینه‌ها)
1. **A — `shamsi_date` 1.0.2 behind the port.** BSD-3-Clause (audit row, status PROTOTYPE). Passes every DT-05 vector (F1). A runtime dependency; 1.1.1 exists and is not audited, so a newer version needs a re-audit (F7). Its own `addMonths` throws on 1405/06/31 + 1 (F4), so it must never be called directly.
2. **B — in-house integer arithmetic behind the same port.** Borkowski's break-year method; the code structure follows jalaali-js (MIT, audit row REFERENCE). Passes every DT-05 vector (F1). No dependency; carries an MIT notice obligation if promoted (audit row `jalaali-js`). Valid for Jalali years −61 … 3177 (`reference_calendar.dart` header).
3. **C — no port, call a library directly.** Rejected: violates DT-05 (one central layer) and ADRX-04's review that no library import exists outside the layer.

## Decision criteria (معیار تصمیم)
ADRX-04: all DT-05 vectors and both DT-02 calendars pass; active maintenance and a suitable licence; if no candidate passes, an in-house adapter behind the date layer. Plus the drivers above.

## Decision (تصمیم) — proposed
**Option B.** The product uses the in-house integer arithmetic behind `JalaliCalendarPort`; no Jalali package is a dependency. This is the default of table 12-1-الف («هیچ کتابخانه‌ای»).
1. One central date layer in `lib/core/` (promotion task, Builder-Domain) exposes the port and `CentralCalendar` (month addition clamped to the last day, validity), as proven in `spike/T-004-jalali/lib/src/calendar_port.dart`. Nothing outside the layer computes Jalali dates (DT-05).
2. Supported range of the layer: Jalali 1279 … 1501 (Gregorian 1900 … 2123), as proposed in F3; inputs outside it are rejected by the layer, not computed.
3. Storage stays Gregorian `yyyy-MM-dd` and UTC instants (DT-01); Jalali values are display and input only.
4. Week start (DT-03) and time zones (DT-02, the `ZoneLayer` of `spike/T-007-timezone/`) are separate settings next to this port and are not part of this decision.

Note on ADRX-04: its wording treats the in-house adapter as the fallback when no library passes. Here both pass (F1, F2), so B is chosen on the other drivers (no dependency, licence, single place for spec rules), not as a fallback. The owner's acceptance settles this; it is not a spec contradiction because B equals the spec default.

## Reasons
- Equal correctness: both implementations pass every DT-05 vector on Linux, macOS, Windows and Chrome and agree on all 81 814 days of 1900-01-01 … 2123-12-31 and on leap years 1279 … 1502 (F1, F2).
- No runtime dependency, no version re-audit (F7), no library call that throws on a spec case (F4).
- Pure integer arithmetic with intermediates far below 2^53, so the same code is exact on the VM and the web (F5).
- The port keeps the choice reversible: A can replace B later by swapping one adapter, with the same vector tests.

## Consequences and trade-offs (پیامدها)
- We maintain about one file of calendar arithmetic ourselves; the DT-05 vectors and the cross-check are its permanent regression tests.
- Both A and B follow the 33-year arithmetic and differ from ICU from 2124-03-20 (Jalali 1502 is 365 days in ICU, 366 in the arithmetic, F3). The range in Decision §2 keeps the app clear of it.
- Promotion obligations (before the layer reaches `lib/`): the jalaali-js MIT notice with its copyright line from the repository `LICENSE` file goes to `third_party/licenses/` and is named in NOTICE (audit row `jalaali-js`, Security & License hat); the `shamsi_date` PROTOTYPE row is closed as "not used".
- Month and weekday names are not computed by the port; they come from the copy catalog (CM-10, DT-05 name table).

## Security, privacy, licensing and operational implications
No network, no platform code, no personal data. Licensing: MIT attribution for the structure taken from jalaali-js (above); no BSD-3 dependency ships. Operational: no package updates to track for the calendar.

## Acceptance test (آزمون پذیرش) — ADRX-04
1. Every DT-05 vector green on the promoted port — today green in the spike (CI run [40745550988](https://github.com/BlueHubbot/BlueHesab-Mini/actions/runs/40745550988), `All tests passed!` on ubuntu, macos, windows and Chrome).
2. PK-15 ت and ث green with the real port — pending: they run with AppDatePicker (M2); until then they are not evidence for or against.
3. Agent 1 reviews that no calendar package or calendar arithmetic is imported outside the date layer (in the spike this is a test: single importer of `shamsi_date`, F4/AC4); the promotion task adds the same check for `lib/`.

## Evidence and links
- `spike/T-004-jalali/README.md` — F1 (vectors), F2 (81 814 days, ICU 224 years), F3 (2124-03-20, range proposal), F4 (`addMonths` throws), F5 (integer arithmetic), F7 (1.1.1 available), "Input for ADR-UI-004".
- `docs/architecture/SPIKE_REPORT.md` §1 row SP-04 (PASS), §4 #3 (Architect's proposal: B).
- `docs/research/OPEN_SOURCE_AUDIT.md` rows `shamsi_date` (BSD-3-Clause, PROTOTYPE) and `jalaali-js` (MIT, REFERENCE, notice condition).
- UI spec: `12-risks-and-adrs.md` table 12-1-الف (ADR-UI-004 row), ADRX-04, RKX-05; `03-typography-rtl.md` DT-01…DT-05; `07-components/7-16-03.md` PK-15.
- Owner-decision record: PR #51 (2026-11-16, not yet on `main` at the time of writing) records "in-house Jalali arithmetic behind the port (ADR-UI-004 to be drafted)".

## Revisit triggers
- A DT-05 vector or the cross-check fails after a change (RKX-05).
- A need for dates outside Jalali 1279 … 1501, or Iran changes its calendar rule (compare with ICU again, F3).
- A second calendar-heavy feature (for example holidays, DT-03) where a maintained library would save more than it costs.

## Status (وضعیت)
PROPOSED. On acceptance the Lead records it in `docs/architecture/DECISIONS.md` and the ADR index; the promotion task for `lib/core/` is then written.

## Related requirements, ADRs and PRs
ADR-0002 (framework), ADR-0003 (storage: Gregorian TEXT dates), ADR-UI-007 (exact numbers on all targets); DATA_MODEL DT-D; T-004 (PR #9), T-007 (PR #12); SPIKE_REPORT; PR #51.
