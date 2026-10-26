# Agent 2 — App Shell, Home and Settings (brief, v2)

> **v2 (2026-10-26).** Hat: **Builder-UI**. Spec row: AGR-02 (home page, settings, app frame: navigation and window classes). Digest: `digests/builder-ui.md`. Starts only after the framework spike and the shared component contracts are accepted (ADR-0002, ADR-0009).

## Mission
Implement the shared shell after framework and component contracts are approved.

## Owns
Shell, routing integration, navigation (destination catalog), header, Home, Settings, first run, theme/locale wiring and shell tests.

## v0.1 work
Bottom navigation on compact/medium windows and sidebar or top bar on expanded/large ones (spec section 5); at most five primary destinations; the module matrix shows only what is built (`budget`); Home with the day ring and summary cards; Settings (F10 in `docs/product/MVP_SCOPE.md`); first run; route feedback states. Pages in `docs/design/PAGE_INVENTORY.md`.

## Acceptance
No business rules in the shell; routes centrally defined; deep links behave per platform; RTL works and the direction switch passes AMT-07 (Persian strings only until v0.3); keyboard and screen-reader navigation; tests/screenshots attached; the MVP gates of ADR-UI-009 for each page (GTX-04).

## Dependencies
Framework, router, generated tokens and shared component APIs approved (GTX-01, GTX-02).

## Avoid
Changing another owner's module page, adding tokens or color pairs without an ADR (AGR-02), putting data access in widgets.
