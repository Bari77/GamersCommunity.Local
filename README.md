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
| RabbitMQ Management | http://localhost:15672 (`admin` / `admin`) |
| SQL Server | `127.0.0.1,14333` (sa / `Your_password123`, Trust server certificate) |

> Port **14333** (not 1433) avoids conflict with a local Windows SQL Server. Prefer `127.0.0.1` over `localhost` under Podman/Windows.

Authentik admin (bootstrap): `admin@gamerscommunity.local` / `admin`.

The blueprint `authentik/blueprints/gc-oidc.yaml` creates the public OIDC client **`gc-front`** (redirect `http://localhost:4200/auth/callback`, `sub` = user UUID).

## Run apps (outside compose)

With infra up, from each repo:

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

Local configs already point at Authentik / Rabbit / SQL containers.

OIDC chain:

- Issuer: `http://localhost:9000/application/o/gc-front/`
- Authorize / token: `http://localhost:9000/application/o/authorize|token`

## Google (optional)

In Authentik → *Federation & Social login* → add Google, link to the auth flow. Not required for daily local work (Authentik local accounts are enough).

## AuthZ

The IdP handles **AuthN** only. Site / game / guild roles live in the **database** (see `sql/001_authz.sql`). The Gateway propagates `Caller` (subject, email, username, JWT roles) on every `BusMessage`.

## Core locally

If `GamersCommunity.Core` is checked out as a sibling, `.csproj` files switch automatically to `ProjectReference` (no need to republish NuGet while iterating).
