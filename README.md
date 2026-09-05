# GamersCommunity — stack locale (Podman)

Infra partagée pour les équipes jeu : **Authentik** (IdP), **RabbitMQ**, **SQL Server**.

## Prérequis

- [Podman](https://podman.io/) (+ `podman compose` / podman-compose)
- Repos frères au même niveau :

```text
repos/
  GamersCommunity.Local/     ← ce repo
  GamersCommunity.Core/
  GamersCommunity.Gateway/
  GamersCommunity.MainSite/
  GamersCommunity.Front/
  GamersCommunity.Games.*/    ← optionnel selon l'équipe
```

## Démarrer l'infra

```powershell
cd GamersCommunity.Local
Copy-Item .env.example .env   # une seule fois
podman compose up -d
```

| Service | URL / port |
|---------|------------|
| Authentik | http://localhost:9000 |
| RabbitMQ Management | http://localhost:15672 (`admin` / `admin`) |
| SQL Server | `127.0.0.1,14333` (sa / `Your_password123`, Trust server certificate) |

> Port **14333** (pas 1433) pour éviter le conflit avec un SQL Server Windows local. Utiliser `127.0.0.1` (pas `localhost`) sous Podman/Windows.

Compte admin Authentik (bootstrap) : `admin@gamerscommunity.local` / `admin`.

Le blueprint `authentik/blueprints/gc-oidc.yaml` crée le client public OIDC **`gc-front`** (redirect `http://localhost:4200/auth/callback`, `sub` = UUID utilisateur).

## Lancer les apps (hors compose)

Avec l'infra up, depuis chaque repo :

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

Configs locales déjà pointées sur Authentik / Rabbit / SQL container.

Chaîne OIDC :

- Issuer : `http://localhost:9000/application/o/gc-front/`
- Authorize / token : `http://localhost:9000/application/o/authorize|token`

## Google (optionnel)

Dans Authentik → *Federation & Social login* → ajouter Google, lier au flow d'auth. Pas requis pour le daily local (comptes Authentik locaux suffisent).

## AuthZ

L'IdP ne gère que l'**AuthN**. Les rôles site / jeu / guilde vivent en **BDD** (voir `sql/001_authz.sql`). La Gateway propage `Caller` (subject, email, username, roles JWT) dans chaque `BusMessage`.

## Core en local

Si `GamersCommunity.Core` est checkout en frère, les `.csproj` basculent automatiquement en `ProjectReference` (plus besoin de republier le NuGet pour itérer).
