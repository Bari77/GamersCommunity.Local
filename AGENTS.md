# Agent guidelines — Local workspace

Multi-root GamersCommunity workspace. Prefer each repo’s own `AGENTS.md` (Template, games, Platform, DevKit, Core, Gateway).

## Always

- **Never start servers** (`dotnet run`, `npm start`, compose app stacks). The developer runs them.
- **Never commit/push** unless explicitly asked.
- Replies to the user in **French** when that is the workspace convention; `AGENTS.md` files stay in **English**.

## Cross-repo

- Database migrations → `Add-Migration.ps1` in the Database project; class-based seeds.
- Fronts → Nebular, English i18n, published packages only, no postinstall package hacks, workspace grids on player/guild/team sheets.
- Game pillar changes → update **Games.Template**; generic shared code → **Core** / DevKit.

## Technical pause

Active hardening plan (no new game features until T1–T3): `docs/SPEC_TECH_PAUSE.md`.
