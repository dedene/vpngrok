# vpnGrok

Run xAI's Grok CLI from any project on your machine, with all its traffic routed through a VPN.

Grok isn't available in every region. This repo puts the Grok CLI in a small Ubuntu container whose only network path is a [gluetun](https://github.com/qdm12/gluetun) VPN tunnel, then gives you a `vpngrok` command that works from any directory. If the tunnel drops, the container loses network entirely instead of leaking your real IP.

Mullvad is the default provider, but gluetun supports [40+ providers](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers) (NordVPN, ProtonVPN, Surfshark, PIA, ...) — see [Other VPN providers](#other-vpn-providers).

## Requirements

- Docker Desktop (or any Docker with compose v2)
- A VPN subscription with WireGuard or OpenVPN support
- macOS or Linux

## Setup

1. Clone the repo:

   ```bash
   git clone https://github.com/dedene/vpngrok.git
   cd vpngrok
   ```

2. Copy the env template and fill in your VPN credentials:

   ```bash
   cp .env.example .env
   ```

   For Mullvad: generate a WireGuard config at
   <https://mullvad.net/en/account/wireguard-config> and copy the `PrivateKey`
   and IPv4 `Address` values into `.env`. Careful: Mullvad rotates the keypair
   on every config download, so the values in `.env` die the next time you
   regenerate a config.

   Also set `WORKSPACE_ROOT` to the directory where your projects live, unless
   that's `~/Development` (the default). `vpngrok` only works inside this tree —
   see [Workspace root](#workspace-root) for why.

3. Start the stack and check that traffic exits through the VPN:

   ```bash
   make up
   make verify
   ```

4. Install the `vpngrok` wrapper on your PATH:

   ```bash
   make install
   ```

## Usage

```bash
cd ~/Development/some-project
vpngrok
```

That's it. The wrapper starts the VPN and dev containers if they aren't running, installs the Grok CLI on first use, and drops you into Grok with your current directory as the working directory. Host paths map 1:1 inside the container.

First run asks you to log in. If the browser flow doesn't cooperate from inside the container, set `XAI_API_KEY` in `.env` instead. Login state persists in `.docker/dev-home`, so you only do this once.

`vpngrok` works in any directory under `WORKSPACE_ROOT` — see below.

## Workspace root

The container mounts one directory tree from your machine, and `vpngrok` only works inside it. It defaults to `~/Development`; set `WORKSPACE_ROOT` in `.env` if your projects live somewhere else:

```bash
WORKSPACE_ROOT=/Users/alice/Projects
```

Why not mount all of `$HOME`? Because whatever is mounted is readable and writable by the container, and by the Grok agent running inside it. Mounting your whole home directory hands over `~/.ssh`, `~/.aws`, browser profiles, documents, everything. Scoping the mount to your projects tree means a misbehaving agent (or a compromised dependency it runs) can only touch code you already intended to share with it.

Performance is not the reason: Docker's VirtioFS mounts are lazy, so a broad mount costs nothing until files are actually accessed. It's purely about blast radius. If you truly want your whole home directory, set `WORKSPACE_ROOT` to its absolute path (e.g. `/Users/alice`) and own the tradeoff (Docker Desktop will show a warning, and macOS may prompt for access to personal folders).

After changing `WORKSPACE_ROOT`, recreate the container: `docker compose up -d --force-recreate dev`.

## Other VPN providers

The vpn container is plain gluetun, so switching providers is an `.env` change. Look up your provider in the [gluetun wiki](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers) and set the matching variables:

```bash
# NordVPN over OpenVPN, for example:
VPN_SERVICE_PROVIDER=nordvpn
VPN_TYPE=openvpn
OPENVPN_USER=...
OPENVPN_PASSWORD=...
```

The compose file passes through `VPN_SERVICE_PROVIDER`, `VPN_TYPE`, `WIREGUARD_PRIVATE_KEY`, `WIREGUARD_ADDRESSES`, `OPENVPN_USER`, `OPENVPN_PASSWORD`, `SERVER_COUNTRIES`, and `SERVER_CITIES`. If your provider needs a variable that isn't in that list, add it to the `vpn` service in `compose.yaml`.

After changing providers: `make down && make up && make verify`.

## How it works

Two containers:

- `vpn` runs gluetun with your provider's credentials. It owns the network.
- `dev` is an Ubuntu box that shares the vpn container's network namespace
  (`network_mode: "service:vpn"`). It has no network of its own, so everything
  it does goes through the tunnel or nowhere.

The `vpngrok` script is a thin wrapper around `docker compose exec` that maps your current directory into the container.

All projects share one container, one Grok login, and one VPN exit server. There is no per-project isolation.

## Kill-switch check

With the stack running, stop the VPN container and confirm the dev container can't reach the internet:

```bash
docker compose stop vpn
docker compose exec dev curl --max-time 10 https://am.i.mullvad.net/ip
```

The curl should time out rather than show your real IP. Bring the tunnel back with:

```bash
docker compose up -d vpn
```

## Make targets

| Target | What it does |
|---|---|
| `make up` | Build and start the vpn + dev containers |
| `make verify` | Confirm traffic exits through the VPN |
| `make install` | Symlink `vpngrok` into your PATH |
| `make shell` | Open a shell in the dev container |
| `make logs` | Tail the vpn container logs |
| `make down` | Stop everything |

## License

MIT
