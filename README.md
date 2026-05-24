# matrix-dotfiles

NixOS flake configuration for a Matrix (Synapse) homeserver running in an Incus container.

## Architecture

```
Internet
    │
    ▼
Ubuntu Server (Caddy) :80/:443
    └── <your-domain> → Incus container (Synapse) :8008
```

- **Host**: Ubuntu Server with Incus and Caddy
- **Container**: NixOS (nixos-unstable) managed by this flake
- **Matrix server**: Synapse with PostgreSQL backend

## Repository Structure

```
.
├── flake.nix
├── flake.lock
├── nixos/
│   ├── configuration.nix   # NixOS base config (networking, users)
│   └── incus.nix           # Hostname
└── modules/
    ├── apps.nix             # System packages and imports
    └── config/
        ├── matrix.nix       # Synapse + PostgreSQL
        ├── fonts.nix
        ├── starship.nix
        └── zsh.nix
```

## Prerequisites

- Ubuntu Server host with Incus installed
- A domain pointing to the server (`<your-domain>`)
- Ghostty terminal (for terminfo setup)

---

## Setup

### 1. DNS

Add an A record pointing to your server's global IP:

```
<your-domain>.  IN  A  <your-server-ip>
```

Verify propagation:

```bash
dig <your-domain>
```

### 2. Host: UFW Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow in on incusbr0
sudo ufw route allow in on incusbr0
sudo ufw route allow out on incusbr0
sudo ufw reload
```

### 3. Host: Install Caddy

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install caddy
```

### 4. Host: Create Incus Container

```bash
incus launch images:nixos/unstable matrix --device root,size=100GiB
```

If the storage pool is too small, expand it first:

```bash
incus storage set default size=<size>  # e.g. 500GiB, 2TiB
```

Add network device if the container has no network interface:

```bash
incus config device add matrix eth0 nic nictype=bridged parent=incusbr0
incus restart matrix
```

### 5. Container: Apply NixOS Configuration

```bash
incus shell matrix
```

```bash
# Inside the container
rm -rf /etc/nixos/*

nix-shell -p git --run \
  "git clone -b claude/funny-allen-5Fitt \
   https://github.com/Myxogastria0808/matrix-dotfiles /etc/nixos"

nixos-rebuild switch --flake /etc/nixos#matrix \
  --option experimental-features "nix-command flakes" \
  --option sandbox false
```

Set a password for the `hello` user:

```bash
passwd hello
```

### 6. Host: Configure Caddy

Find the container's IP:

```bash
incus list matrix
```

Edit `/etc/caddy/Caddyfile`:

```caddyfile
{
    email <your-email>
}

<your-domain> {
    reverse_proxy <container-ip>:8008
}
```

```bash
sudo systemctl reload caddy
```

### 7. Ghostty Terminfo

Install the Ghostty terminfo into the container (run from local machine):

```bash
infocmp -x xterm-ghostty | incus exec matrix -- \
  su -c "mkdir -p ~/.terminfo && tic -x -o ~/.terminfo -" hello
```

### 8. Create Matrix Admin User

```bash
incus exec matrix -- register_new_matrix_user \
  -c /etc/matrix-synapse/homeserver.yaml \
  -a http://localhost:8008
```

---

## Maintenance

Inside the container as `hello`:

```bash
# Apply config changes
nixos           # alias for: sudo nixos-rebuild switch --flake /etc/nixos#matrix --option sandbox false

# Pull latest dotfiles
git -C /etc/nixos pull && nixos

# Garbage collect old Nix generations
gc
```

---

## Troubleshooting

### Container has no network

```bash
# On host: add network device
incus config device add matrix eth0 nic nictype=bridged parent=incusbr0
incus restart matrix

# If still no route: check UFW allows bridge traffic
sudo ufw allow in on incusbr0
sudo ufw route allow in on incusbr0
sudo ufw route allow out on incusbr0
```

### Nix sandbox error

LXC containers do not support kernel namespaces required for sandboxing:

```bash
nixos-rebuild switch --flake /etc/nixos#matrix \
  --option experimental-features "nix-command flakes" \
  --option sandbox false
```

### Disk full during nixos-rebuild

```bash
# Free space
nix-collect-garbage -d

# Or expand the storage pool on the host
incus storage set default size=<size>  # e.g. 500GiB, 2TiB
```
