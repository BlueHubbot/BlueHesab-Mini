# Project Charter — BlueHesab Mini (v2)

**Status:** v2 (2026-10-26) replaces the pack's v1. The owner decisions of 2026-10-25 are folded in. If this file and `docs/ops/STATUS.md` ever differ, STATUS wins; scope details live in `docs/product/MVP_SCOPE.md`, decisions in `docs/architecture/DECISIONS.md` and ADR-0007/0008/0009.

**خلاصه‌ی فارسی:** آبی‌حساب برنامه‌ای رایگان، متن‌باز (Apache-2.0)، فارسی‌محور و محلی‌محور برای مدیریت مالی شخصی است که بعداً ماژول‌های اختیاری (کارها، بازار، خودرو، سلامت، دستیار محلی) می‌گیرد. نسخه‌ی ۰٫۱ فقط هسته‌ی مالی است: ثبت سریع، خانه، حساب‌ها و تراکنش‌ها، بودجه‌ی ساده، گزارش ماهانه، ثبت از پیامک (چسباندن یا Share) و پشتیبان‌گیری.

## Vision
A free, open-source, Persian-first and local-first app for personal money management that grows into an optional-module life-management app (tasks, markets, car, health, local AI assistant). Core flows work offline with no account; the user's data stays on the device unless the user exports it.

## Target platforms (ADR-0009)
- Android, Windows, macOS and iOS are built and tested in CI from the first milestone (M0).
- First public release (v0.1): Android (APK), Windows (installer), macOS (DMG). iOS is released only after the owner buys an Apple Developer account.
- Web is a demo of the Style Guide and MotionLab only. It is not a product and stores no user data.
- Platform capabilities and their evidence: `docs/architecture/PLATFORM_MATRIX.md`.

## Principles
1. Local-first core: no account, no cloud, no telemetry in v0.x.
2. User control over permissions, export and deletion. Anything that touches the network is optional, off by default, and listed in `PRIVACY.md`.
3. Modular boundaries and versioned contracts. A module that is off, or not built, leaves no trace (DM-01, `MODULE_CONTRACT.md`).
4. Persian first: RTL, Jalali calendar, Persian digits, toman/rial from the base design. English texts arrive in v0.3; layout is LTR-ready and tested from v0.1.
5. Accessibility and responsive layouts are acceptance criteria.
6. Reliable backup/export and data portability (`BACKUP_RESTORE.md`).
7. Evidence-driven dependency selection (`docs/research/OPEN_SOURCE_AUDIT.md`). No license or capability claim without a recorded check.
8. Human confirmation for anything automated that would create a financial record: SMS, OCR and AI produce drafts, never saved records.
9. Incremental delivery with tested milestones M0–M3. The MVP profile (ADR-UI-009) lightens gates but never weakens money, RTL, accessibility or privacy rules.
10. Distinguish planned, implemented, tested and unsupported behavior in every document and public claim.
11. Minimal human work: one Lead agent is the owner's only contact; questions reach the owner only when the decision is his (`docs/agents/AUTONOMY_AND_ESCALATION.md`).

## Modules and release plan
Owner-visible plan: `docs/product/MODULE_ROADMAP.md` (the only place that carries version numbers).
- **Core (v0.1):** app shell, Home, QuickAdd, accounts, categories, transactions, reports, settings, backup/restore, SMS paste/share capture, module registry.
- **Budget (v0.1):** the only optional module in v0.1, on by default.
- **Later, one at a time:** tasks → markets and finance depth, English UI → local AI assistant → car and health → full quality profile and iOS.
- **Optional and separate:** sync, end-to-end encryption, optional cloud (ADR-0005/0006). They need their own design and security review.

## MVP (v0.1)
Defined in `docs/product/MVP_SCOPE.md` (features F01–F16, success criteria S-01–S-08, milestones M0–M3). The earlier "MVP candidate" list of the v1 charter is superseded by it.

## Non-goals for the first releases
- Replacing a full ERP; tax or legal advice.
- Guaranteed live market data without a verified provider.
- Unattended AI financial actions.
- Accounts, cloud, sync, or any mandatory network use.
- Reading SMS through an operating-system permission (users paste or share the message).
- Web as a product, or an iOS release before the Apple account exists.
- A large local model on every device.
- Wholesale embedding of third-party applications without the license review.

## Success criteria
- The measurable criteria S-01…S-08 of `MVP_SCOPE.md` §2 are met with recorded evidence.
- Core finance works offline and survives restart; migration and backup/restore are tested (I-09, I-10).
- Repeated actions never duplicate or lose a transaction (I-05).
- Locale, theme, digits and unit changes never mutate stored values (I-02).
- No dependency is approved without license and maintenance evidence.
- Every PR passes the relevant tests and an independent review.

## Open questions
Tracked only in `docs/ops/OPEN_QUESTIONS.md`.
