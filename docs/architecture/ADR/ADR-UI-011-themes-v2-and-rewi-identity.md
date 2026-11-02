# ADR-UI-011: Rewi identity, four themes, automatic and custom themes
- **Status:** ACCEPTED (direction decided by the product owner on 2026-10-31 and 2026-11-01; exact token values become binding when T-012 lands them in `design/tokens/design_tokens.json` with green VT checks)
- **Date:** 2026-11-01
- **Owner:** Product/Contracts (Agent 1 role) — drafted by the Lead
- **Approver:** Product owner

## Context and problem
The first token palette (cool blue/slate, `primary #2563EB`) was rejected by the owner on 2026-10-31 as generic. The product was renamed **Rewi** (Persian: «رِوی»). A new identity was designed and shown on the design canvas «Rewi — هویت و ویژن»: a geometric silhouette fox mascot, a fox-in-sun logo, four themes taken from the owner's reference photos, wide display typography and big numbers. On 2026-11-01 the owner decided how themes behave for users.

## Decision drivers
Owner taste (Apple-like restraint, warm multi-layer colour, a lovable mascot for all ages); accessibility (VT checks, 4.5:1 text contrast); unambiguous digits in a finance app; no third-party design assets (all drawn in-house, Apache-2.0).

## Options considered
1. One fixed theme. Rejected by the owner.
2. Light/dark only. Rejected: the owner asked for colour sets, not only light and dark.
3. **Four named themes + automatic by time of day + a user-made custom theme.** Chosen.

## Decision
1. **Themes.** Four themes ship and the user picks one in Settings: **عاج / Ivory**, **آلو / Plum**, **سفال / Clay**, **شب‌تاب / Glow**. Values per role (bg, surface, surface2, ink, text2, line, accent, onaccent), scene colours, mascot colours and four activity colours are in `design/brand/themes-v2.json`. They replace the colour part of `design/tokens/design_tokens.json` through T-012; spacing, radius, size and motion tokens are unchanged unless T-012 records a reason.
2. **Automatic.** A setting «خودکار» switches theme by local time. Default schedule: 06:00 Ivory, 11:00 Clay, 17:00 Plum, 21:00 Glow; the user can edit the hours. The switch never happens while a sheet or a form is open (applied on next screen change) and respects reduced motion.
3. **Custom theme («تم من»).** The user builds a theme by picking colours for bg, surface, text and accent: first from the curated palette (`custom_palette` in `themes-v2.json`, our own colours), or freely with a colour picker. A contrast guard computes WCAG ratios live: text below 4.5:1 (3:1 for ≥24 px) is not allowed; the app proposes the nearest passing shade or switches text to the theme's ink/ivory automatically. Saving an unreadable theme is not possible. Custom themes are stored locally and included in backups.
4. **Mascot.** The fox «رِوی» is a one-colour silhouette in the theme's mascot colour with an amber/theme eye and a light tail tip; seven poses (hero, wave, think, celebrate, worried, sleep, peek) map to app states. Source SVGs: `design/brand/mascot/`.
5. **Logo.** Fox bust inside a sun circle; wordmark «Rewi» with the i-dot as the sun; Persian wordmark «رِوی». Files: `design/brand/logo/`.
6. **Typography.** Persian headings: Alexandria. **All digits** (amounts, times, percentages) and Persian body text: Vazirmatn — Alexandria's light ۴ is too close to ۳ for money. Latin display: Archivo at width 125; Latin UI: SF Pro on Apple platforms, Inter elsewhere. Fonts are OFL-1.1 (license rows to be added by the Security & License hat before bundling).

## Reasons
Owner decisions (DECISIONS.md, 2026-10-31 and 2026-11-01); the four palettes were sampled from the owner's reference photos and every text pair was checked (Ivory 16.5/6.9, Plum 15.7/8.6, Clay 14.4/6.5 on cream surfaces, Glow 18.2/8.3).

## Consequences and trade-offs
- `design_tokens.json` gets a new major version with themes instead of a light/dark pair; `ui_check tokens` and the 210 contrast checks must be extended to four themes (T-012). AX-02 checksum changes.
- The UI spec sections that name the old palette need an erratum or edit by Product/Contracts (AG-02) in T-012.
- A theme engine with a custom-theme editor and contrast guard is new app work (T-013, after T-012).
- Clay uses a mid-tone background: on it only `on_bg_text` (5.0:1) may carry small text.

## Security, privacy, licensing and operational implications
No network or telemetry. Custom themes are local data. Fonts: Alexandria, Vazirmatn, Archivo, Inter are OFL-1.1; SF Pro is used only as the platform system font on Apple devices (not bundled).

## Evidence and links
`design/brand/themes-v2.json`, `design/brand/README.md`, design canvas «Rewi — هویت و ویژن» (owner's claude.ai artifact).

## Revisit triggers
User tests show a theme fails readability or confuses money colours; the owner changes the brand.

## Related requirements, ADRs and PRs
ADR-UI-001 (visual direction, superseded in its colour part by this ADR), ADR-UI-003 (font, ESC-001), ADR-UI-009, T-010, T-012, T-013.
