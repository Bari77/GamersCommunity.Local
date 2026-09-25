# Agent guidelines — Local workspace

Multi-root GamersCommunity workspace hub.

**Shared module:** [`AgentKit/`](AgentKit/) (submodule → [GamersCommunity.AgentKit](https://github.com/Bari77/GamersCommunity.AgentKit))

| Doc | Path |
|-----|------|
| Engineering standards | [`AgentKit/ENGINEERING_STANDARDS.md`](AgentKit/ENGINEERING_STANDARDS.md) |
| Shared agent base | [`AgentKit/AGENTS.base.md`](AgentKit/AGENTS.base.md) |
| Override policy | [`AgentKit/POLICY.md`](AgentKit/POLICY.md) |
| AgentKit adoption | [`docs/SPEC_AGENTKIT.md`](docs/SPEC_AGENTKIT.md) |
| Tech pause | [`docs/SPEC_TECH_PAUSE.md`](docs/SPEC_TECH_PAUSE.md) |
| Tech evolution | [`docs/SPEC_TECH_EVOLUTION.md`](docs/SPEC_TECH_EVOLUTION.md) |

## Always

- Follow **`AgentKit/AGENTS.base.md`** and **`AgentKit/ENGINEERING_STANDARDS.md`**.
- Prefer each product repo’s thin `AGENTS.md` when working inside that repo.
- Replies to the user in **French** when that is the workspace convention; AgentKit / `AGENTS*` stay in **English**.

## Repo-specific

- Orchestration docs and Compose/Authentik live here; do not put package architecture that belongs in DevKit.
- After updating AgentKit upstream: `git submodule update --remote AgentKit` then `./AgentKit/scripts/Sync-CursorRules.ps1`.

## Optional overrides

`AGENTS.override.md` at this root only for Local-specific exceptions (`AgentKit/POLICY.md`).
