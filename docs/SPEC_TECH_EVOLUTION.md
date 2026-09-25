# Spec — Technical evolution (post tech-pause)

**Status:** Active backlog  
**Depends on:** `SPEC_TECH_PAUSE.md` (T1–T7 largely done)  
**Related:** `SPEC_AGENTKIT.md`, `AgentKit/ENGINEERING_STANDARDS.md`  
**Goal:** Close remaining structural debt identified in the post-pause audit, without opening a new product feature wave until each milestone’s acceptance is met (or explicitly deferred).

---

## 1. Context

The technical pause (`SPEC_TECH_PAUSE.md`) delivered:

- Core RPC / Platform clients / Consumer host / seed framework / realtime / UTC JSON  
- DevKit game remote kernel (`gc-sdk`) + media / entity-wall / LFG chat shells  
- Gateway BusInternal hygiene + federation contracts  
- LoL i18n pipeline parity  

A workspace audit (front + backend) then found **no critical backend regression**, but several **follow-ups** that still cause twin drift or incomplete publish trains.

This spec turns those findings into **descriptive milestones** (not bare letters).

---

## 2. Locked decisions

- **No new game product features** that create LoL↔WoW UI/service twins until **E1** is done and **E2** is either done or explicitly deferred by a lead.
- **Published packages only** — DevKit/Core changes ship via registry tags; never `file:` / local `dist`.
- **Template remains scaffold truth** — pillar changes land in Template in the same wave.
- **Domain asymmetry stays** — do not unify Team/Guild models under this spec.
- **AgentKit rollout** is specified in `SPEC_AGENTKIT.md` (milestone **E0** here only links it).

---

## 3. Milestones

### E0 — AgentKit module (governance)

**Repos:** Local, then all product repos (see `SPEC_AGENTKIT.md`).  
**Why:** Single versioned home for engineering standards and agent rules.

| Done when |
|-----------|
| [ ] `GamersCommunity.AgentKit` repo exists (or Local `AgentKit/` staging is declared interim source of truth) |
| [ ] `ENGINEERING_STANDARDS.md` + `AGENTS.base.md` live in AgentKit |
| [ ] Override model documented and used by at least one repo |
| [ ] Thin root `AGENTS.md` pattern applied to Local |

---

### E1 — DevKit patch train `1.0.3` (federation kernel completeness)

**Repos:** DevKit, Platform.Front, LoL.Front, WoW.Front, Template.Front.  
**Why:** `provideGameRemoteKernel` on `main` already registers `playerSheetApi`, but **published `v1.0.2` does not**. Consumers work around it by listing `PlayersService` next to the kernel.

#### Deliverables

- [ ] `CHANGELOG.json` entry for **1.0.3** (kernel registers `playerSheetApi`; docs already describe it)
- [ ] Lockstep bump all `@bari77/gc-*` to **1.0.3**, tag **`v1.0.3`**, publish via release workflow
- [ ] Bump Platform / LoL / WoW / Template Fronts to **1.0.3** (keep `@bari77/*` aligned)
- [ ] Optionally simplify `app.config.ts` comments that say “until ≥ 1.0.3” once consumed
- [ ] Confirm playground WoW/LoL still resolve `GameMembershipStore` at root without NG0201

#### Acceptance

- [ ] `npm view @bari77/gc-sdk version` (authed) reports `1.0.3`
- [ ] All game/Platform Fronts lock to 1.0.3; no mixed lockstep versions
- [ ] Standalone `:4201` / `:4202` and federated shell still boot

---

### E2 — Consumer helpers in Core (pause T3 P2)

**Repos:** Core, LoL.Consumer, WoW.Consumer (Template if stubs help).  
**Why:** Exact twins remain:

- `SearchHandle.Split` (LoL ↔ WoW)  
- `RequestPayload.SentFields` (LoL ↔ WoW)  
- Inline `Take(take + 1)` / `hasMore` cursor pattern across list endpoints  

#### Deliverables

- [ ] Core helpers, e.g.:
  - `SearchHandle.Split(query)` → `(Name, Discriminator?)`
  - `RequestPayload.SentFields(json)` → case-insensitive property set
  - `QueryCursor.TakePlusOne(take)` / small page helper returning `(items, hasMore)`
- [ ] LoL + WoW Consumers delete local copies and use Core
- [ ] Bump **GamersCommunity.Core** (and Logging if needed); consumers reference the new version
- [ ] Mark T3 P2 checkbox done in `SPEC_TECH_PAUSE.md`

#### Acceptance

- [ ] No second `SearchHandle` / `RequestPayload` class in game Consumers  
- [ ] Search and partial-update behaviour unchanged (handles, clear-vs-omit fields, pagination)

---

### E3 — Playground shell extraction (`gc-playground`)

**Repos:** DevKit (`gc-playground`), LoL.Front, WoW.Front, Template.Front.  
**Why:** Near-identical twins:

- `playground-context-bar.component.ts` (~256 lines each)  
- Header session chip + MSW banner pattern in `app.ts`  
- `playground-session` / `playground-user-profile` stubs  
- Local `provide-playground-ui.ts` vs package UI helper  

#### Deliverables

- [ ] Parametrized playground pieces in `@bari77/gc-playground` (game URL, i18n inputs/labels, optional session binding)
- [ ] LoL + WoW remotes become thin wrappers (`$localize` + persona/mock wiring only)
- [ ] Template gains the same shell parity (banner / context bar / `users/*` stubs **or** documented minimal mode)
- [ ] Publish DevKit bump (likely **1.0.4** if E1 already shipped 1.0.3); bump consumers
- [ ] Align `providePlaygroundUi` usage with the package export (NbFormField/Input included once)

#### Acceptance

- [ ] No 250-line context-bar twin left in LoL/WoW  
- [ ] New game from Template can enable playground chrome without copying WoW files  
- [ ] MSW `Users.Touch` (or successor) remains covered where membership header is shown  

---

### E4 — Template federation / DI parity

**Repos:** Template.Front (and create-game docs).  
**Why:** Template still lags production remotes: minimal `app.ts`, no kernel, `ItemsService` may still use `providedIn: "root"`.

#### Deliverables

- [ ] Documented path: either wire a demo `provideGameRemoteKernel` + stub `PlayersService`-shaped API, **or** keep Template UI-only with an explicit README section “kernel required when adding membership”
- [ ] Remove or quarantine `providedIn: "root"` on services that would break under federation once a kernel exists
- [ ] `gameNav` / `gameSearch` data shape on Template routes when playground chrome is enabled (ties to E3)
- [ ] create-game / Template README points at AgentKit + engineering standards

#### Acceptance

- [ ] A developer scaffolding from Template cannot accidentally ship a federated remote with root-provided kernel services  
- [ ] README states the chosen Template stance clearly  

---

### E5 — Hygiene / documentation drift

**Repos:** LoL.Front docs, WoW.Front leftovers, pin style.  
**Why:** Low risk, high confusion for AI and humans.

#### Deliverables

- [ ] Fix LoL specs that still mention a **LFG board** as current (`SPEC_PLAYER_SHEET.md` etc.); point to home LFG chats  
- [ ] Remove dead Angular CLI artefacts if confirmed unused (e.g. orphan `app.html` on WoW)  
- [ ] Align `@bari77/gc-workspace-editor` pin style (`1.0.x` vs `^1.0.x`) across LoL / WoW / Template  
- [ ] Optional: Gateway/contracts note that `LfgAds.Search` remains available though LoL Front no longer exposes a board  

#### Acceptance

- [ ] Specs match shipped LoL LFG behaviour  
- [ ] No misleading dead files in default playground paths  

---

### E6 — Optional later (explicitly deferred unless pulled in)

Not required to close this evolution wave:

| Item | Note |
|------|------|
| Generic `PlatformEventsSubscriber` in Core | Thin DbContext-coupled twins are acceptable |
| Promote `create-sheet-wall` into DevKit | Fine as thin `gc-create-wall` wrappers |
| Extract LFG SignalR service into DevKit | Stores/realtime stay in remotes per T5 unless a clear generic hub helper appears |
| Drop unused `LfgAds.Search` from Gateway | Product/API decision — keep until a deprecation ticket |
| Historical WoW `InsertData` guild ranks rewrite | Documented non-goal |

---

## 4. Suggested order

| Order | Milestone | Blocks features? |
|-------|-----------|------------------|
| 1 | **E1** DevKit 1.0.3 | Soft — do first (small, unblocks clean kernel) |
| 2 | **E0** AgentKit | Soft — governance; can parallel E1 |
| 3 | **E2** Core P2 helpers | Soft — closes pause T3 |
| 4 | **E3** Playground package | Yes for more playground/UI twins |
| 5 | **E4** Template parity | Yes for new games |
| 6 | **E5** Doc/hygiene | Parallel anytime |

Resume larger **product** UI that would copy LoL↔WoW structure after **E3** (or with an explicit lead exception).

---

## 5. Definition of done (wave)

- [ ] E1 published and consumed  
- [ ] E2 in Core and consumers bumped  
- [ ] E0 at least staged (Local AgentKit) with a path to the GitHub module  
- [ ] E3 either completed or deferred in writing with owner + date  
- [ ] `SPEC_TECH_PAUSE.md` T3 P2 checked when E2 lands  
- [ ] No new `file:` DevKit deps; lockstep `@bari77/*` intact  

---

## 6. Non-goals

Same as engineering standards / tech pause:

- Team/Guild domain merge  
- Gateway routing rewrite  
- Platform profile workspace grid  
- Events / scrims product delivery disguised as evolution  

---

## 7. Traceability (audit → milestone)

| Audit finding | Milestone |
|---------------|-----------|
| Kernel `playerSheetApi` on main, not in `v1.0.2` | **E1** |
| `SearchHandle` / `SentFields` / `Take+1` twins | **E2** |
| Playground context-bar / session / profile twins | **E3** |
| Template kernel / playground lag | **E4** (+ E3) |
| LFG board doc drift, pin style, dead `app.html` | **E5** |
| Central AGENTS / standards | **E0** / `SPEC_AGENTKIT.md` |
