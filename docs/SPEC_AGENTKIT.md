# Spec — GamersCommunity.AgentKit (shared engineering / agent module)

**Status:** Active (repo live; rollout in progress)  
**Repo:** https://github.com/Bari77/GamersCommunity.AgentKit  
**Goal:** One central place for engineering conditions, agent guidelines, and Cursor rules — consumed by every GamersCommunity repo as a **Git submodule** at `AgentKit/`, with optional **per-repo overrides**.

---

## 1. Problem

AI/engineering guidance was **duplicated and fragmented** across fat `AGENTS.md` files. Drift between LoL / WoW / Platform / Template was inevitable.

## 2. Decision

**`Bari77/GamersCommunity.AgentKit`** is the shared module.

```text
<repo>/
  AgentKit/              ← submodule → GamersCommunity.AgentKit
  AGENTS.md              ← thin local entrypoint (required)
  AGENTS.override.md     ← optional local-only rules
  .cursor/rules/         ← synced from AgentKit via scripts/Sync-CursorRules.ps1
```

**Why submodule:** docs/rules are not runtime packages; every stack can consume them; pin tags for reproducible agent behaviour; overrides stay outside the module.

## 3. Precedence

1. Current chat instruction  
2. `AGENTS.override.md`  
3. Thin root `AGENTS.md`  
4. `AgentKit/AGENTS.base.md` + `ENGINEERING_STANDARDS.md` + `cursor/rules/*`

See `AgentKit/POLICY.md`.

## 4. Rollout checklist

| ID | Title | Status |
|----|-------|--------|
| **I1 — Module repo** | Populate + push AgentKit | [x] |
| **I2 — Local hub** | Submodule + thin AGENTS + docs | [x] |
| **I3 — Platform + Gateway + Core + DevKit** | Submodule + thin AGENTS | [x] |
| **I4 — Games + Template** | Submodule + thin AGENTS | [x] |
| **I5 — Create-game docs** | Document `git submodule update --init AgentKit` | [ ] follow-up |

## 5. Add / update submodule

```powershell
cd <product-repo>
git submodule add https://github.com/Bari77/GamersCommunity.AgentKit.git AgentKit
git submodule update --init --recursive
./AgentKit/scripts/Sync-CursorRules.ps1
```

## 6. Related

- Evolution backlog: `SPEC_TECH_EVOLUTION.md` (E0 = AgentKit rollout)  
- Tech pause: `SPEC_TECH_PAUSE.md`
