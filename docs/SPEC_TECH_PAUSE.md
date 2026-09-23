# Spec — Technical pause (architecture hardening)

Cross-repo hardening before the next game feature wave. Source: architecture review (Local canvas `architecture-tech-pause`). Goal: stop LoL↔WoW twin growth, close AGENTS.md gaps, keep product behaviour unchanged.

## Locked decisions

- **No big-bang rewrite.** Extract high-leverage twins only; leave domain asymmetry (Team vs Guild, Characters, etc.).
- **No new game features** until **T1–T3** are done (backend mutualization). Front kernel (**T4–T5**) should land before the next large remote feature.
- **Published packages only.** DevKit changes are published, then consumers bump versions — never `file:` / local `dist`.
- **Template stays the scaffold of truth.** Any new Consumer/Database pillar lands in Template (and Core when generic).
- **Migrations** only via each Database project’s `Add-Migration.ps1`. Seeds = class-based under `Seed/` (framework may live in Core).
- **Do not drop** WoW Events schema or unfinished `SPEC_EVENTS` roadmaps — product future, not tech-pause scope.
- **Platform profile** stays without workspace grid (shell, not a game sheet).

## Out of scope (explicit)

- New LoL/WoW product features (LFG depth, Events/scrims, etc.).
- Unifying Team and Guild domain models.
- Rewriting Gateway routing tables from scratch.
- Migrating historical WoW `InsertData` guild ranks out of old migrations (document only; optional later consolidation).

## Done already (pre-pause cleanup)

- [x] Core: remove obsolete `RabbitMQProducer.SendMessageAsync` / `GetResponseAsync` (keep `CallAsync`)
- [x] WoW: remove unused `EventSummaryDto`, orphan `wow-game-video`, unused TipTap/dompurify front deps
- [x] Workspace-wide `AGENTS.md` rules

---

## T1 — Unify Rabbit RPC and Platform clients in Core

**Repos:** Core, Gateway, LoL.Consumer, WoW.Consumer (Platform only if it gains a shared client).  
**Why:** largest backend duplication (~Platform*Client + Gateway `RabbitRpcClient`).

### Deliverables

- [x] Single RPC surface in Core on top of `RabbitMQProducer.CallAsync` (e.g. `IRabbitRpcClient` or thin wrapper) with shared timeout / envelope / error mapping
- [x] Move shared clients into Core (or `GamersCommunity.Core` subfolder/package):
  - [x] `PlatformSanctionsClient`
  - [x] `PlatformConversationsClient` (generic channel helpers; LoL “Guild*” method names → neutral/`Team*` naming where LoL-specific)
  - [x] `PlatformFriendsClient` (already WoW-only; live in Core for reuse)
- [x] Gateway consumes the same Core RPC helper instead of a private `RabbitRpcClient` twin where possible
- [x] LoL + WoW Consumers delete local Integration copies and DI-register Core types
- [x] Bump Core package version; Consumers/Gateway reference it
- [x] Update Template Consumer DI stubs / comments so new games get the clients by default when needed

### Acceptance

- [x] No second copy of sanctions/conversations RPC call loops in game repos
- [x] Mute + team/guild Whispers still work unchanged for LoL and WoW (behaviour preserved; verify manually after deploy)
- [x] DevKit `DevGateway` keeps using Core `CallAsync` (or the new wrapper)

---

## T2 — Seed framework in Core and align Template

**Repos:** Core, Platform.Database, LoL.Database, WoW.Database, Games.Template.  
**Why:** AGENTS rule + three identical seed frameworks; Template has no class-based seeds.

### Deliverables

- [x] Move seed framework to Core (`IReferenceTableSeed`, `KeyTableSeed`, discovery, `SeedTotals`, `ReferenceTableSeed` base / discovery helpers)
- [x] Keep **only domain `*Seed` classes** in each `*.Database/Seed/`
- [x] Align LoL `CatalogRows` (or equivalent) into Core if still needed for tests — no LoL-only framework drift
- [x] Template: add `Database/Seed/` + runtime `ReferenceDataSeed.EnsureAsync` after migrate (same hook as games)
- [x] Template: replace demo `Items` `InsertData` in `InitialCreate` with a seed class (or document a one-time exception and stop adding migration seeds)
- [x] Document WoW legacy `InsertData` guild ranks in migration as historical; new ranks only via `GuildRanksSeed`
- [x] Update Template `Program.cs` migrate+seed path; sync README if needed

### Acceptance

- [x] Platform / LoL / WoW still seed at Consumer startup
- [x] New game from Template gets class-based seed pipeline without copying framework files
- [x] No new seed rows added via EF migrations

---

## T3 — Consumer host bootstrap and shared realtime helpers in Core

**Repos:** Core, Platform.Consumer, LoL.Consumer, WoW.Consumer, Template.Consumer.  
**Why:** `Program.cs` / `ConsumerWorker` / realtime publisher / UTC JSON converter are near-clones.

### Deliverables

- [x] Core host helper (e.g. `AddGamersCommunityConsumerHost<TContext, TConsumer>(...)`) covering: Serilog wiring pattern, Rabbit options, SQL + `UseGamersCommunitySqlServer`, Scrutor `IBusService`, Health, BusRouter, Worker, `ApplyMigrationsWithRetryAsync` + optional `afterMigrate` seed delegate
- [x] Thin per-repo `Program.cs` (game-specific DI only: sanctions, whispers, friends, authZ, etc.)
- [x] Move `UtcDateTimeJsonConverter` to Core; Gateway + Consumers consume it
- [x] Move `RealtimeEventPublisher` + shared `RealtimeQueues` constants to Core (or Core.Realtime); delete per-repo twins
- [ ] Optional P2 in same wave or follow-up: `SearchHandle`, `RequestPayload.SentFields`, cursor `Take+1` helper
- [x] Mirror host pattern in Template

### Acceptance

- [x] LoL / WoW / Platform / Template build and start migrate+seed as before
- [x] One implementation of realtime publish + UTC converter

---

## T4 — Game remote kernel in DevKit (`gc-sdk`)

**Repos:** DevKit (`gc-sdk`), LoL.Front, WoW.Front, Template.Front.  
**Why:** stop copying membership/session/base HTTP helpers on every remote feature.

### Deliverables

- [x] Extract shared Angular pieces (parametrized by game id / gateway paths):
  - [x] `GameMembershipStore` (or factory)
  - [x] `PlatformSessionService`
  - [x] `platform-games` service helpers
  - [x] Shared `BaseService` / resource / promise utils if still duplicated
- [x] Publish `@bari77/gc-sdk` bump; LoL / WoW / Template consume published version
- [x] Delete local twins; keep game-only adapters thin
- [x] Docs snippet in DevKit for “new game remote kernel”

### Acceptance

- [x] LoL and WoW membership + game switcher behaviour unchanged
- [x] No `file:` deps; versions aligned

---

## T5 — Shared media and entity walls in DevKit (`gc-widgets` / `gc-ui`)

**Repos:** DevKit, LoL.Front, WoW.Front.  
**Why:** media feature and team/guild walls are structural twins.

### Deliverables

- [x] Generic media feature shell (stores/services/components) configurable per game
- [x] Generic “entity wall” (list + post form + applications/apply hooks) for team/guild
- [ ] Optional: base `entity-row` in `gc-ui` with slots for WoW-only facts
- [ ] Optional: LFG chat shell shared where LoL board vs WoW home-only is config, not a fork *(deferred — low leverage vs team/guild divergence)*
- [x] Publish packages; remotes thin wrappers for `$localize` / routes only

### Acceptance

- [x] Media galleries and walls still work on player / team / guild sheets
- [x] New wall-like surface can be added without copying three folders

---

## T6 — Close i18n gaps (LoL + Platform)

**Repos:** LoL.Front, Platform.Front (Template.Front optional align).  
**Why:** AGENTS i18n rule partial; LoL lacks locale pipeline WoW/Platform already have.

### Deliverables

- [ ] LoL: align `angular.json` i18n / `localize` with WoW; add `src/locale` + `extract-i18n` script
- [ ] Platform: `$localize` breadcrumbs / game names in `app.routes.ts` (and staff role option labels if still hardcoded)
- [ ] Spot-fix remaining hardcoded game display names in heroes when cheap
- [ ] Template: optional same locale pipeline as games for scaffold parity

### Acceptance

- LoL can extract and build with `fr` (or documented locale list) like WoW
- No new hardcoded user-facing strings in touched files

---

## T7 — Gateway hygiene and federation contracts

**Repos:** Gateway, Platform.Consumer, LoL/WoW `contracts/federation.contract.json`.  
**Why:** orphan DI services, missing routes, stale federation manifests.

### Deliverables

- [ ] Decide per Platform service: **route it** or **exclude from bus scan** if internal-only (`Cities`, `FriendStatuses`, `EventsUsersStatuses`, …)
- [ ] Expose or remove `Friends.Delete` (handler vs Gateway asymmetry)
- [ ] Refresh federation contracts from Gateway truth (LoL incomplete; WoW resources empty)
- [ ] Document Template microservice stance: either add `template` routes for Items demo, or keep Template offline from main Gateway and say so in Template README
- [ ] Quick Public/Private audit on any new routes added during T1–T3

### Acceptance

- No “DI yes / Gateway never” surprise for scannable CRUD services (documented exceptions OK)
- Federation contracts list the resources remotes actually call

---

## Suggested order

| Order | Milestone | Blocks features? |
|-------|-----------|------------------|
| 1 | **T1** RPC + Platform clients | Soft — do first |
| 2 | **T2** Seed + Template | Soft — AGENTS compliance |
| 3 | **T3** Host + realtime helpers | Soft — reduces Program drift |
| 4 | **T4** Front kernel | Yes for large remote UI |
| 5 | **T5** Media / walls | Yes for sheet-related UI |
| 6 | **T6** i18n | Parallel OK after T4 start |
| 7 | **T7** Gateway / contracts | Parallel OK anytime after T1 |

Resume game feature work after **T1–T3** minimum; prefer **T4** before another LoL↔WoW UI twin.

## Non-goals checklist (do not “fix” during pause)

- [ ] WoW Events tables / Event Front
- [ ] LoL scrims Events product
- [ ] Platform user profile workspace grid
- [ ] Merging Team and Guild APIs
