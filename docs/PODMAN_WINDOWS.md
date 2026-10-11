# Podman on Windows — one-time setup

Apps in this workspace expect infra on **`127.0.0.1`** (Rabbit `5672`, SQL `14333`, Authentik `9000`). On Windows, Podman’s WSL machine often publishes ports only on the VM’s eth0 IP, not on the host loopback. Without the steps below, Gateway fails with `BrokerUnreachableException` / connection refused on `127.0.0.1:5672` even when containers are healthy.

Run the setup script once after installing Podman (and again after recreating the machine if ports break):

```powershell
cd GamersCommunity.Local
# Elevated PowerShell (Administrator) — required for localhost portproxy
./scripts/Setup-PodmanWindows.ps1
```

Then start the stack as usual (`./scripts/up.ps1` or `podman compose up -d`).

`up.ps1` refreshes the `127.0.0.1` → WSL IP mappings when it can (admin session). If not elevated, it prints the exact command to re-run.

---

## What the setup does

| Step | Why |
|------|-----|
| Write `%AppData%\containers\containers.conf` | Avoids `crun: controller pids is not available` when starting containers |
| Ensure a Compose provider exists | `podman compose` needs `docker-compose` or `podman-compose` on `PATH` |
| `netsh interface portproxy` → WSL eth0 | Makes published container ports reachable as `127.0.0.1` on every PC |
| Refuse WSL `networkingMode=mirrored` | Mirrored networking breaks `podman machine` SSH/API on current Podman/WSL |

Do **not** put the WSL IP (`172.x.x.x`) into appsettings — it changes after machine recreate. Always keep app configs on `127.0.0.1` and refresh portproxy instead.

---

## Manual checklist (if you prefer not to use the script)

### 1. Compose provider

```powershell
winget install Docker.DockerCompose
# reopen the terminal, then:
podman compose version
```

Avoid the Store stub under `...\WindowsApps\docker-compose.exe` if it misbehaves; a real Compose binary is fine.

### 2. `containers.conf` (cgroup / pids)

Create or replace `%AppData%\Roaming\containers\containers.conf`:

```toml
[containers]
pids_limit = 0

[engine]
cgroup_manager = "systemd"
```

Also mirror the same file to `%USERPROFILE%\.config\containers\containers.conf` if you use that path.

If you still see `controller pids is not available` on old containers stuck in `Created`:

```powershell
podman compose down
podman rm -f gc-mssql gc-rabbitmq gc-authentik-db gc-authentik-redis gc-authentik-server gc-authentik-worker
podman machine stop
podman machine start
podman compose up -d
```

### 3. Localhost portproxy (Administrator)

With the machine running and the stack up:

```powershell
$wslIp = (
  wsl -d podman-machine-default -- ip -4 -br addr show eth0
) -replace '.*?(\d+\.\d+\.\d+\.\d+).*', '$1'

foreach ($p in 5672, 15672, 9000, 9443, 14333) {
  netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=$p 2>$null
  netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=$p connectaddress=$wslIp connectport=$p
}

netsh interface portproxy show all
```

Verify:

```powershell
# AMQP
Test-NetConnection 127.0.0.1 -Port 5672
# Rabbit management
Invoke-WebRequest http://127.0.0.1:15672 -UseBasicParsing | Select-Object StatusCode
```

Re-run this block (or `./scripts/Sync-LocalhostPorts.ps1` as Administrator) after `podman machine rm` / recreate, or whenever the WSL eth0 IP changes.

### 4. Do not enable WSL mirrored networking for Podman

`%USERPROFILE%\.wslconfig` must **not** contain:

```ini
[wsl2]
networkingMode=mirrored
```

Mirrored mode can make `podman machine start` fail (`machine is not listening on ssh port` / API pipe missing). Prefer default NAT networking + portproxy.

Optional safe snippet:

```ini
[wsl2]
localhostForwarding=true
```

(`localhostForwarding` alone does **not** replace portproxy for Podman-published ports.)

---

## Machine recreate

```powershell
podman machine stop
podman machine rm -f          # answer is -f; do not type the next command at the [y/N] prompt
podman machine init --rootful
podman machine start
./scripts/Setup-PodmanWindows.ps1   # Admin — rewrite conf + portproxy
./scripts/up.ps1
```

---

## Smoke targets (always `127.0.0.1`)

| Service | Address |
|---------|---------|
| RabbitMQ AMQP | `127.0.0.1:5672` |
| RabbitMQ UI | http://127.0.0.1:15672 (`admin` / `admin`) |
| SQL Server | `127.0.0.1,14333` |
| Authentik | http://127.0.0.1:9000 |

Gateway / consumers / Fronts already use these hosts in Development configs — no per-machine IP edits.

---

## Related (not Podman)

- **NuGet GitHub Packages** — see root [README.md](../README.md) (“Core NuGet”).
- **npm `@bari77/*`** — Front `.npmrc` + `$env:NODE_AUTH_TOKEN` (PAT `read:packages`).
- **PowerShell `npm.ps1` blocked** — `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` or use `npm.cmd`.
