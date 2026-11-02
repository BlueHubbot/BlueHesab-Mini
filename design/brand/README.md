# Rewi brand assets

Source of truth for the identity decided in ADR-UI-011. Drawn in-house; same license as the project (Apache-2.0).

- `logo/rewi-mark.svg` — fox bust inside the sun circle (ink fox, amber sun). `rewi-mark-ivory-on-dark.svg` for dark backgrounds. Minimum size 16 px.
- `logo/rewi-wordmark*.svg` — «Rewi» outlined from Archivo (width 125, weight 820); the i-dot is the sun. Persian wordmark «رِوی» is set in Alexandria Bold until it is outlined.
- `mascot/rewi-{hero,wave,think,celebrate,worried,sleep,peek}.svg` — the fox in seven poses, drawn in Ivory colours (ink `#0E0B05`, eye `#E39A2E`, tail tip `#FBF6EA`). In other themes recolour: body → `mascot.fox`, eye → `mascot.eye`, tail tip → `mascot.tail_tip` from `themes-v2.json`.
- `themes-v2.json` — the four themes (roles, scene, mascot and activity colours), the default automatic schedule and the curated palette for custom themes.

Pose → app state: hero = calm home; wave = greeting, morning, first run; think = assistant reading an SMS or receipt; celebrate = goal reached, month under budget; worried = close to a budget limit, overdue instalment; sleep = night or several idle days; peek = card edges and notifications.
