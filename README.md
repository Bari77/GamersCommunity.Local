# GamersCommunity — local stack (Podman)

Shared infra for game teams: **Authentik** (IdP), **RabbitMQ**, **SQL Server**.

## Prerequisites

- [Podman](https://podman.io/) (+ `podman compose` / podman-compose)
- Sibling repos at the same level:

```text
repos/
  GamersCommunity.Local/     ← this repo
  GamersCommunity.Core/
  GamersCommunity.Gateway/
  GamersCommunity.MainSite/
  GamersCommunity.Front/
  GamersCommunity.DevKit/     ← optional (leads); game teams use @bari77/gc-create-game
  GamersCommunity.Games.*/    ← optional per team
```

## Start infra

```powershell
cd GamersCommunity.Local
Copy-Item .env.example .env   # once
podman compose up -d
```

| Service | URL / port |
|---------|------------|
| Authentik | http://localhost:9000 |
| RabbitMQ | `127.0.0.1:5672` (AMQP), management http://localhost:15672 (`admin` / `admin`) |
| SQL Server | `127.0.0.1,14333` (sa / `Your_password123`, Trust server certificate) |

> Port **14333** (not 1433) avoids conflict with a local Windows SQL Server. Prefer `127.0.0.1` over `localhost` under Podman/Windows (IPv6/`localhost` quirks).

Authentik admin (bootstrap): `admin@gamerscommunity.local` / `admin`.

The blueprint `authentik/blueprints/gc-oidc.yaml` creates the public OIDC client **`gc-front`** (redirect `http://localhost:4200/auth/callback`, `sub` = user UUID).

## Canonical local ports (platform mode)

Do **not** run a game-full compose (WoW/Template) at the same time as this stack — Rabbit `5672` and SQL `14333` collide.

| App | How | URL |
|-----|-----|-----|
| Gateway | `cd Gateway && dotnet run` | http://localhost:5000 |
| MainSite consumer | `cd MainSite.Consumer && dotnet run` | (worker, no HTTP) |
| Front (shell) | `cd GamersCommunity.Front && npm start` | http://localhost:4200 → API `http://localhost:5000/api` |
| WoW consumer (optional) | `cd WorldOfWarcraft.Consumer && dotnet run` | uses Local Rabbit + SQL |

Development configs already use:

- SQL `127.0.0.1,14333` / `Your_password123`
- Rabbit `127.0.0.1` / `admin` / `admin`
- OIDC authority `http://localhost:9000/application/o/gc-front/`

## Run apps (outside compose)

```powershell
# Gateway
cd GamersCommunity.Gateway/Gateway
dotnet run

# MainSite
cd GamersCommunity.MainSite/MainSite.Consumer
dotnet run

# Front
cd GamersCommunity.Front
npm start
```

OIDC chain:

- Issuer: `http://localhost:9000/application/o/gc-front/`
- Authorize / token: `http://localhost:9000/application/o/authorize|token`
- Login UI: http://localhost:4200/users/login

Smoke checks:

```powershell
# Gateway health (aggregates MainSite / WoW consumers over Rabbit)
Invoke-RestMethod http://localhost:5000/api/health
```

## Google (optional)

In Authentik → *Federation & Social login* → add Google, link to the auth flow. Not required for daily local work (Authentik local accounts are enough).

## AuthZ

The IdP handles **AuthN** only. Site / game / guild roles live in the **database** (see `sql/001_authz.sql`). The Gateway propagates `Caller` (subject, email, username, JWT roles) on every `BusMessage`.

## Core NuGet (GitHub Packages)

Consumers depend on published packages only (`GamersCommunity.Core`, etc.) — never on a sibling checkout path.

Authenticate once (PAT with `read:packages`):

```powershell
dotnet nuget update source github `
  --source https://nuget.pkg.github.com/Bari77/index.json `
  --username YOUR_GITHUB_USER `
  --password ghp_xxx `
  --store-password-in-clear-text
```

Each game / Gateway / MainSite repo already has a `nuget.config` that lists the `github` source and maps `GamersCommunity.*` to it (`packageSourceMapping`). Without credentials, restore falls back to nuget.org and fails for `>= 9.4.0`.

If your user `%AppData%\NuGet\NuGet.Config` already uses `packageSourceMapping` (e.g. Azure DevOps feeds), add:

```xml
<packageSource key="github">
  <package pattern="GamersCommunity.*" />
</packageSource>
```

Otherwise NuGet ignores the GitHub feed even with a valid PAT (« versions de github n'ont pas été prises en compte »).
