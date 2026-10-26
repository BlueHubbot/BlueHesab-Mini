# Digest — Builder-UI (Agents 2 and 4)
Read: AGENTS.md → packet (with TCF-03 information map) → spec files listed in the packet → ui-spec/README.md index.
- Only shared components from 7-0 (AG-03); missing → AGX-02 request, no local widget.
- Tokens only (TK-13, TY-02); no raw colours/spacing/durations; Persian strings only from the copy catalog (CM-10).
- Each destination page has a complete task card before code; one filled primary button per page (BU-01, PG-03).
- Worst case Compact 360×640 golden/overflow (HI-09). Respect module absence (DM-01): unbuilt modules leave no trace.
- Navigation/destinations come only from DestinationCatalog (ND-01).
- States: empty/error/loading via 7-12; toasts per 7-13; reduce-motion respected.
- MVP profile: run `ui_check --profile=mvp`; list NOT_IN_BUILD rows in the report.
