# Work Mac (`.#work`)

The work machine is Apple Silicon, enrolled in **Intune**, supervised, signed in
with a Managed Apple Account (iCloud Drive off, OneDrive instead), and running
**Microsoft Defender for Endpoint**. This document covers what that changes.

## The governing rule

> **nix-darwin owns ergonomics. MDM owns compliance controls.**

This is not politeness — it is a failure mode. `networking.applicationFirewall`
is implemented as `socketfilterfw` calls in an activation script. If a config
profile has the firewall locked, that command errors, the activation script
exits non-zero, and **the entire `just switch` fails**. You would lose the
ability to rebuild at all, over a setting that was never going to apply.

So the work host does not manage:

| Setting | Where it lives | Why it's excluded |
|---|---|---|
| Application firewall, stealth mode, guest login | `modules/darwin/firewall.nix` (not imported) | Can hard-fail activation |
| `hostName` / `localHostName` / `computerName` | `modules/darwin/hostname.nix` (not imported) | Intune enforces naming and re-renames on check-in |
| `power.sleep` | `preferences.nix`, gated by `isWork` | Idle/display sleep is a compliance control |
| `screensaver.askForPassword*` | `preferences.nix`, gated by `isWork` | Profile always wins; would be dead config |

Kept, because MDM baselines essentially never touch them: Finder, Dock,
trackpad, key repeat, accent colour, hot corners, input sources, screenshots
location, fonts, timezone, and Touch ID for `sudo`.

## Anonymization contract

This repo is public. **Never commit** the employer name, work email, internal
hostnames, or internal domains. Two consequences:

- `modules/home/links.nix` **globs** `~/Library/CloudStorage/OneDrive-*` instead
  of hardcoding the tenant name, which is part of the path.
- Work git identity and the internal SSH host block live in hand-created files
  **outside** this repo. A `.gitignore`d file would not work — Nix flakes only
  copy git-tracked files into the store, so an untracked `local.nix` is
  invisible to `nix build`.

## If the machine is not fresh

Run the pre-flight check before anything else. It is read-only and prints the
exact command to clear each finding.

```bash
./scripts/preflight.sh work     # or `just preflight` once just is on PATH
```

Four things collide on a machine that already has software on it:

**Apps that are also in the cask list.** `brew install --cask ghostty` aborts
with *"It seems there is already an App at /Applications/Ghostty.app"* when the
app exists and brew did not put it there. That fails `brew bundle`, which fails
the whole switch. Delete the app first — brew reinstalls it and takes ownership,
and your settings in `~/Library` survive untouched.

**A leftover `~/.gitconfig`.** Home Manager writes `~/.config/git/config`, but
git reads *both* files and `~/.gitconfig` is read **last**, so its values win. A
`[user] email` in there silently overrides `user.useConfigOnly` and re-enables
exactly the wrong-identity commit this config is built to prevent. Home Manager
will not warn you, because it never manages that path.

```bash
mv ~/.gitconfig ~/.gitconfig.pre-nix
```

**`~/.ssh/config`.** Home Manager replaces it. Copy any Host blocks you still
need into `~/.ssh/config.local` *first* — otherwise they survive only inside
`~/.ssh/config.hm-backup`.

**Docker Desktop.** Fights Colima over the `docker` CLI and socket, and carries
the same commercial-licence problem as OrbStack. Uninstall it.

Everything else Home Manager touches (`~/.zshrc`, `~/.tmux.conf`,
`~/.config/nvim`, `~/.config/ghostty/config`) is moved aside automatically by
`backupFileExtension = "hm-backup"`.

## First-time setup

Steps 2–5 cannot be automated and must be done by hand.

**1. Install prerequisites**

```bash
xcode-select --install
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Open a new terminal afterwards.

**2. Generate fresh SSH keys — do not copy `id_ed25519` from `beast`**

A key on a supervised device can be remotely wiped, inspected, or reclaimed on
your last day. A separate key is revocable in one click without touching
anything personal. Add the first one to GitHub as a *second* key.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "work-mac"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_work -C "work-mac internal"
```

**3. Create the unmanaged SSH host block**

```bash
touch ~/.ssh/config.local && chmod 600 ~/.ssh/config.local
```

```
Host <internal-host>
  HostName <internal-host>
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

**4. Create the unmanaged work git identity**

```bash
mkdir -p ~/.config/git && printf '[user]\n\tname = <name>\n\temail = <work email>\n' > ~/.config/git/work.inc
```

Git carries two identities here, because this repo is itself a personal public
one that gets cloned on the work Mac. There is deliberately **no default**:

- `~/work/` → work identity, from the file above
- `~/projects/` → personal identity, managed in `modules/home/git.nix`
- anywhere else → `user.useConfigOnly = true` makes git **refuse** to commit

That last case is the point. A stray clone in `~/Downloads` is exactly when you
should be forced to decide which hat you are wearing, rather than silently
pushing your work email to a public repo.

**5. Sign into OneDrive** so `~/Library/CloudStorage/OneDrive-<Tenant>` exists
before the first switch, or the `~/onedrive` symlink is skipped.

## Staged rollout

A VM cannot reproduce Intune, config profiles, or Defender — the interesting
failures only appear on the real machine. So stage the activation, and make each
failure attributable to one layer.

```bash
# 1. On beast — catches every eval/build error, no sudo, no risk
darwin-rebuild build --flake .#work

# 2. On work — home-manager and packages only, zero system.defaults
git clone git@github.com:Wheel-Smith/nix-config.git ~/projects/nix-config
cd ~/projects/nix-config
sudo nix run nix-darwin -- switch --flake .#work-minimal

# 3. On work — the full configuration
just switch
```

`just` auto-detects the host from `id -un`, so `just switch` resolves to
`.#work` here and `.#beast` on the personal machine. Override with
`just host=work-minimal switch`.

Delete `hosts/work-minimal/` and its flake output once step 3 succeeds.

## Defender and `/nix/store`

Defender's real-time protection scans every file written to disk, and a Nix
build writes tens of thousands of small files. Expect `wdavdaemon` to pin a core
and slow builds noticeably.

Benchmark a real switch first, then ask IT for a folder exclusion on `/nix` only
if it actually hurts. Note that **local exclusions are locked when Defender is
managed by Intune** — `mdatp exclusion folder add` will be rejected, so only IT
can add it via a configuration profile.

```bash
mdatp health --field real_time_protection_enabled
```

## Containers

OrbStack and Docker Desktop both require a **paid licence for commercial use**,
so neither belongs on an employer's machine without one. The work host uses
**Colima** (Apache-2.0) with the `docker` CLI, which keeps `d`, `lazydocker`, and
the `remote-containers` / `vscode-containers` extensions working unchanged.

```bash
colima start
```

`docker compose` works because `modules/home/containers.nix` links the v2 plugin
into `~/.docker/cli-plugins/`.

## Homebrew

`cleanup = "uninstall"` is safe here: brew only uninstalls what is in its own
registry, and apps Intune deploys as `.pkg`/`.dmg` are invisible to it.

> **Hard rule: never add a cask for an app Intune deploys** — Teams, Outlook,
> Office, OneDrive, Edge, Company Portal, Defender, the VPN client.
> `onActivation.upgrade` would bump it on every switch, Intune would revert it
> on every check-in, and the two would fight forever.

## Things that are deliberately absent

- **Network security tooling** (`caido` is present by explicit choice;
  `wireshark`, `nmap` are not) — port scanning and packet capture on a corporate
  network trip IDS and are hard to defend in an audit.
- **Tailscale** — a mesh tunnel bypassing corporate network controls.
- **Personal VPN, mail, drive, password manager** — personal accounts on a
  device your employer can inspect cuts both ways.
- **AI coding tools** (`claude`, `claude-code`, `codex`, `opencode`, `ollama`) —
  using a personal account on employer source routes their IP through a contract
  they are not party to.
- **`mas`** — a Managed Apple Account cannot purchase from the Mac App Store.
- **Raycast** — so ⌘Space stays bound to Spotlight, and the
  `com.apple.symbolichotkeys` unbind is gated off.
- **Nix-managed VS Code extensions** — `mutableExtensionsDir = true` here, so
  VS Code installs its own. Settings are still managed.

## Known rough edges

**Aerospace and TCC.** Accessibility grants are keyed to a binary's path and
signature, and Aerospace lives at a `/nix/store/<hash>-aerospace-…/` path that
changes on every package update. A version bump can silently drop the grant and
you re-approve it. Not specific to the work Mac.

**Tiling and video calls.** Teams and Zoom floating call/screen-share windows
sometimes fight the tiler. Fix with a float rule, not by dropping Aerospace.
