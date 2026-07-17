# rattatui — macOS nix-darwin configuration

Declarative macOS setup powered by [nix-darwin](https://github.com/nix-darwin/nix-darwin),
[home-manager](https://github.com/nix-community/home-manager), and
[nix-homebrew](https://github.com/zhaofengli/nix-homebrew).

The goal: take a **brand-new Mac** from factory state to a fully configured
system with a handful of commands — no manual app installs, no interactive
Homebrew prompts, no clicking through GUI installers.

| | |
|---|---|
| **Host** | `beast` |
| **User** | `rattatui` |
| **Platform** | `aarch64-darwin` (Apple Silicon) |
| **Homebrew** | pinned to `6.0.11` via `nix-homebrew` (tap-trust aware, Golden Gate-ready) |

---

## Prerequisites

1. **macOS** on Apple Silicon (tested on macOS 27 "Golden Gate" beta).
2. **Xcode Command Line Tools** — needed for `git` before Nix is installed:
   ```bash
   xcode-select --install
   ```
3. **A Nix installer.** This config works with both Nix and Lix. The
   [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer)
   is recommended because it enables flakes out of the box and ships a clean
   uninstaller:
   ```bash
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   ```
   Open a **new terminal** afterwards so `nix` is on your `PATH`.

> If you use a different installer, make sure flakes are enabled:
> `experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`.

---

## Bootstrap from scratch

```bash
# 1. Clone the config
git clone https://github.com/Wheel-Smith/nix-config.git ~/nix-config
cd ~/nix-config

# 2. Build & activate the system for the first time.
#    On a fresh machine neither `darwin-rebuild` nor `just` are on PATH yet,
#    so run the activation straight from the flake output:
sudo nix run nix-darwin -- switch --flake .#beast
```

That single activation will:

- install and pin **Homebrew** under `/opt/homebrew` (via `nix-homebrew`),
- create the unified `brew` launcher at `/run/current-system/sw/bin/brew`,
- apply declarative **tap trust** for the third-party `xykong/tap`,
- run `brew bundle` to install every brew and cask in
  [`modules/darwin/homebrew.nix`](modules/darwin/homebrew.nix),
- install the `just` task runner and the rest of your packages,
- activate **home-manager** for `rattatui`.

**Open a new terminal** when it finishes so `brew`, `darwin-rebuild`, `just`,
and your home-manager tools land on `PATH`.

---

## Day-to-day usage

This repo ships a [`justfile`](justfile) so common tasks are short, memorable
commands. **`just` is installed declaratively** (it's in the Nix config — do
**not** `brew install` it), so after your first switch it's on `PATH`.

```bash
just                 # list all recipes
just switch          # apply the configuration
just build           # preview changes without activating
just check           # validate the flake evaluates
just update          # update all inputs and re-lock
just upgrade         # update inputs, then switch
just rollback        # revert to previous generation
just clean           # garbage-collect old generations
just generations     # list system generations
```

> ⚠️ **Chicken-and-egg:** on a brand-new machine `just` doesn't exist yet, so
> the very first activation uses the raw command (or `just bootstrap-switch`,
> which simply wraps it). Every rebuild after that can use `just switch`.

The equivalent raw commands, if you ever need them without `just`:

```bash
cd ~/nix-config
sudo darwin-rebuild switch --flake .#beast   # apply
darwin-rebuild build --flake .#beast         # preview
nix flake check                              # validate
```

### Making `just` available

Add it to your packages so it's reproducible. Either in a nix-darwin module:

```nix
environment.systemPackages = [ pkgs.just ];
```

…or via home-manager:

```nix
home.packages = [ pkgs.just ];
```

### Updating dependencies

Inputs are pinned in `flake.lock`. To move them forward:

```bash
just update                    # update everything
just update-input nixpkgs      # or a single input
```

> ⚠️ Because `nix-darwin.inputs.nixpkgs.follows = "nixpkgs"`, always keep
> `nixpkgs` and `nix-darwin` moving **together**. A `nix-darwin` that is newer
> than your `nixpkgs` can fail the docs build with
> `nixos-render-docs: error: unrecognized arguments: --sidebar-depth`.

**Always commit `flake.lock`.** Nix only copies git-tracked files into the
flake, so an uncommitted lock will not reproduce on a fresh machine:

```bash
git add flake.nix flake.lock modules/
git commit -m "update: bump inputs"
git push
```

---

## Hostname / computer name

macOS exposes **three** separate name fields. Setting only `hostName` (as the
original config did) leaves the friendly "Computer Name" untouched, which is why
the machine may still show up as `<username>s-MacBook-Pro`. Set all three for a
consistent identity — see [`modules/darwin/hostname.nix`](modules/darwin/hostname.nix):

| nix-darwin option | `scutil` key | What it controls |
|---|---|---|
| `networking.hostName` | `HostName` | CLI / SSH hostname (`localHostName` defaults to this) |
| `networking.localHostName` | `LocalHostName` | Bonjour / `.local` network name |
| `networking.computerName` | `ComputerName` | Friendly name in Finder ▸ Sharing (spaces/Unicode OK) |

```nix
networking = {
  hostName = "beast";
  localHostName = "beast";
  computerName = "beast";
};
```

After `just switch`, open a **new terminal** (or reboot) to see the prompt
update. A reboot guarantees every subsystem picks up the change.

---

## Managing packages

### Homebrew (casks & GUI apps)

Edit [`modules/darwin/homebrew.nix`](modules/darwin/homebrew.nix):

```nix
brews = [ "lazyssh" "mole" "opencode" ];   # CLI formulae
casks = [ "ghostty" "raycast" /* ... */ ]; # GUI apps
```

`onActivation.cleanup = "uninstall"` means anything **not** in these lists gets
uninstalled on the next rebuild — the config is the single source of truth.

### Adding a third-party tap

Third-party taps require two coordinated changes (Homebrew 6.0 **tap trust**):

1. Register the tap as a flake input in `flake.nix` (`flake = false`) and add it
   to `nix-homebrew.taps`.
2. Trust the specific item declaratively:
   ```nix
   nix-homebrew.trust = {
     casks    = [ "xykong/tap/flux-markdown" ]; # item-level (preferred)
     formulae = [ ];
     commands = [ ];
     taps     = [ ];                            # or whole-tap trust
   };
   ```
3. Reference the item **fully-qualified** in `homebrew.nix`
   (e.g. `"xykong/tap/flux-markdown"`), and make sure the token matches the
   trust entry exactly (mind the hyphen).

> Official taps (`homebrew/core`, `homebrew/cask`, `homebrew/bundle`) are
> trusted automatically — no `trust` entry needed.
>
> Trust entries are **add-only**: removing one from the list does **not** revoke
> it. Run `brew untrust <item>` manually to revoke.

---

## Repository layout

```
nix-config/
├── justfile                     # task runner recipes (just switch, just update, …)
├── flake.nix                    # inputs, host definition, nix-homebrew + tap trust
├── flake.lock                   # pinned dependency revisions (commit this!)
├── hosts/
│   └── beast/                   # host-specific configuration
└── modules/
    └── darwin/
        ├── homebrew.nix         # declarative brews / casks
        └── hostname.nix         # hostName / localHostName / computerName
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `The option 'nix-homebrew.trust' does not exist` | `flake.lock` pins a `nix-homebrew` commit older than the tap-trust feature (PR #157) | `just update-input nix-homebrew` |
| `nixos-render-docs: error: unrecognized arguments: --sidebar-depth` | `nix-darwin` is newer than `nixpkgs` | `just update-input nixpkgs` (keep them in sync). Temporary bypass: `documentation.enable = false;` |
| `Homebrew requires formulae to be in a tap, rejecting` | Old `nix-homebrew` rejecting `/nix/store`-backed taps (issue #148) | `just update-input nix-homebrew` (needs the PR #150 fix) |
| `Refusing to load … from untrusted tap` | Third-party tap not trusted | add a `nix-homebrew.trust` entry |
| `Untapping … Permission denied` on activation | `homebrew.taps` empty while taps exist on disk, so cleanup tries to untap read-only Nix-store taps | add `homebrew.taps = builtins.attrNames config.nix-homebrew.taps;` |
| `brew bundle` cleanup fails needing `--force` | Homebrew 6.0 CLI flag change (issue #1787) | update `nix-darwin` past PR #1789, or set `homebrew.onActivation.extraFlags = [ "--force-cleanup" ];` |
| `brew` / `just` / `darwin-rebuild` not found right after activation | Shell session predates activation | open a new terminal; for brew specifically, `/run/current-system/sw/bin/brew` |
| `warning: Git tree … has uncommitted changes` | Working tree not committed | harmless; `git commit` to silence |

---

## Notes

- **Do not install Homebrew or `just` manually** — `nix-homebrew` installs and
  pins Homebrew, and `just` comes from your Nix packages. Manual installs will
  conflict with the Nix-managed copies.
- **Golden Gate:** `brew-src` is pinned to `6.0.11`, the first Homebrew line
  with initial macOS 27 support. Keep this pin while on the beta.
- **Verify casks installed:** `brew list --cask | wc -l`.
