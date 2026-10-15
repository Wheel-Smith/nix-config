# rattatui — macOS nix-darwin configuration

Declarative macOS setup powered by [nix-darwin](https://github.com/nix-darwin/nix-darwin),
[home-manager](https://github.com/nix-community/home-manager), and
[nix-homebrew](https://github.com/zhaofengli/nix-homebrew).

The goal: take a **brand-new Mac** from factory state to a fully configured
system with a handful of commands — no manual app installs, no interactive
Homebrew prompts, no clicking through GUI installers.

| Host | User | Machine |
|---|---|---|
| `beast` | `rattatui` | Personal Mac — owns everything about itself |
| `work` | `kristjan` | MDM-managed work Mac — see [`docs/work-mac.md`](docs/work-mac.md) |

Both hosts are `aarch64-darwin` (Apple Silicon) on macOS 27 "Golden Gate",
with Homebrew installed and locked by `nix-homebrew` (tap-trust aware).

`just` picks the host automatically from `id -un`, so `just switch` means the
right thing on either machine.

---

## Prerequisites

1. **macOS** on Apple Silicon (in use on macOS 27.0.1 "Golden Gate").
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

> Bootstrapping the **work** Mac is different — it needs hand-created identity
> files, fresh SSH keys, and a staged activation. Follow
> [`docs/work-mac.md`](docs/work-mac.md) instead of this section.

```bash
# 1. Clone the config
git clone https://github.com/Wheel-Smith/nix-config.git ~/projects/nix-config
cd ~/projects/nix-config

# 2. Check for anything that would collide with the first switch
#    (read-only; prints the exact fix for every finding)
./scripts/preflight.sh beast

# 3. Build & activate the system for the first time.
#    On a fresh machine neither `darwin-rebuild` nor `just` are on PATH yet,
#    so run the activation straight from the flake output:
sudo nix run nix-darwin -- switch --flake .#beast
```

> **Secrets first.** `beast` decrypts `secrets/personal.yaml` during
> activation, so the machine needs its own age key and must be a recipient in
> `.sops.yaml` *before* the first switch, or activation stops halfway. The
> preflight check flags this; the steps are in
> [`secrets/README.md`](secrets/README.md).

That single activation will:

- install and pin **Homebrew** under `/opt/homebrew` (via `nix-homebrew`),
- create the unified `brew` launcher at `/run/current-system/sw/bin/brew`,
- apply declarative **tap trust** for any third-party taps,
- run `brew bundle` to install every brew and cask in
  [`hosts/beast/homebrew.nix`](hosts/beast/homebrew.nix),
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
just diff            # show what would change (package versions, etc.)
just check           # validate the flake evaluates
just update          # update all inputs and re-lock
just upgrade         # update inputs, switch, then upgrade Homebrew packages
just brew-upgrade    # only the Homebrew upgrade (if `upgrade` stopped after the switch)
just verify          # assert the activated system matches the config
just rollback        # revert to previous generation
just clean           # delete generations older than 7 days
just generations     # list system generations
just preflight       # collision check before a first switch
just secrets         # edit secrets/personal.yaml (sops)
just ssh-sync        # save LazySSH host edits into the secrets (runs before switch)
```

> ⚠️ **Chicken-and-egg:** on a brand-new machine `just` doesn't exist yet, so
> the very first activation uses the raw command (or `just bootstrap-switch`,
> which simply wraps it). Every rebuild after that can use `just switch`.

The equivalent raw commands, if you ever need them without `just`:

```bash
cd ~/projects/nix-config
sudo darwin-rebuild switch --flake .#beast   # apply
darwin-rebuild build --flake .#beast         # preview
nix flake check                              # validate
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

> **`beast` only.** `hostname.nix` is not imported on the work host — the MDM
> owns that machine's name and would revert us on every check-in. The `hostName`
> passed to `mkDarwin` only names the flake output and the `hosts/` directory;
> it is never written to `networking.*`.

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

Each host has its own list: [`hosts/beast/homebrew.nix`](hosts/beast/homebrew.nix)
and [`hosts/work/homebrew.nix`](hosts/work/homebrew.nix).

```nix
brews = [ "lazyssh" "mole" ];              # CLI formulae
casks = [ "ghostty" "vicinae" /* ... */ ]; # GUI apps
```

Prefer nixpkgs for CLI tools (`modules/home/packages.nix`, or a topic module
such as `kubernetes.nix`); Homebrew is for GUI apps and the odd formula
nixpkgs lacks.

`onActivation.cleanup = "uninstall"` means anything **not** in these lists gets
uninstalled on the next rebuild — the config is the single source of truth.

### Adding a third-party tap

Third-party taps require two coordinated changes (Homebrew 6.0 **tap trust**):

1. Register the tap as a flake input in `flake.nix` (`flake = false`) and add it
   to `nix-homebrew.taps`.
2. Trust the specific item declaratively:
   ```nix
   nix-homebrew.trust = {
     casks    = [ "someuser/tap/some-cask" ];  # item-level (preferred)
     formulae = [ ];
     commands = [ ];
     taps     = [ ];                            # or whole-tap trust
   };
   ```
3. Reference the item **fully-qualified** in `homebrew.nix`
   (e.g. `"someuser/tap/some-cask"`), and make sure the token matches the
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
├── flake.nix                    # inputs, host definitions, nix-homebrew + tap trust
├── flake.lock                   # pinned dependency revisions (commit this!)
├── hosts/
│   ├── beast/                   # personal: dock, homebrew, packages; imports firewall/hostname
│   └── work/                    # work: dock, homebrew, packages (no firewall/hostname)
├── overlays/                    # package overrides (OmniWM pinned, debugpy test skip)
├── scripts/                     # preflight.sh (before switch), verify-host.sh (after), ssh-sync.sh
├── secrets/                     # sops-encrypted secrets (committed; beast only)
├── docs/                        # bootstrap, work Mac, VM testing, rollback, post-install
├── wallpapers/                  # SVG sources; rasterised at build time (beast only)
└── modules/
    ├── darwin/                  # default.nix = the set safe on EVERY host (incl. skhd.nix)
    ├── home/                    # home-manager; gated by isWork where hosts differ
    │   ├── containers.nix       # Colima + docker CLI (loopback-only port forwards)
    │   ├── kubernetes.nix       # k8s Colima profile (k3s), kubectl/helm/kind + scanners
    │   ├── secrets.nix          # sops-nix wiring
    │   └── omniwm/              # window manager + its vendored defaults-<version>.toml
    └── shared/                  # letter-workspaces.nix, read by skhd.nix and omniwm/
```

Hosts share code through an `isWork` flag threaded via `specialArgs`:

- **Identical on both** — `nix`, `system`, `finder`, `trackpad`, `keyboard`,
  `screenshots`, `fonts`, `security`, and all the shell/editor modules.
- **Shared, forked internally by `isWork`** — `preferences.nix`, `skhd.nix`,
  `omniwm/`, `letter-workspaces.nix`, `packages.nix`, `git.nix`, `ssh.nix`,
  `links.nix`, `vscode.nix`, `wallpaper.nix`, `secrets.nix`, `kubernetes.nix`
  (smaller VM on work).
- **Per-host files** — `dock.nix`, `homebrew.nix`, `packages.nix` under
  `hosts/<host>/`.
- **`beast`-only** — `firewall.nix` and `hostname.nix` (compliance controls the
  MDM owns on the work Mac; see [`docs/work-mac.md`](docs/work-mac.md) for why
  importing them there can hard-fail activation), `playwright.nix`, and anything
  from a third-party flake (the `sofka` Kubernetes TUI).

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `The option 'nix-homebrew.trust' does not exist` | `flake.lock` pins a `nix-homebrew` commit older than the tap-trust feature (PR #157) | `just update-input nix-homebrew` |
| `nixos-render-docs: error: unrecognized arguments: --sidebar-depth` | `nix-darwin` is newer than `nixpkgs` | `just update-input nixpkgs` (keep them in sync). Temporary bypass: `documentation.enable = false;` |
| `Homebrew requires formulae to be in a tap, rejecting` | Old `nix-homebrew` rejecting `/nix/store`-backed taps (issue #148) | `just update-input nix-homebrew` (needs the PR #150 fix) |
| `unknown keyword: :overwrite` (or any *"formula is unreadable"*), then `brew bundle can't satisfy your Brewfile` | `brew-src` runtime older than the `homebrew-core`/`homebrew-cask` inputs, which have adopted a newer DSL | `just update` (`brew-src` tracks Homebrew's `master`, so it moves with the taps); if `brew-src` was pinned to a tag, unpin it or bump the tag |
| `just switch` dies at "Homebrew bundle…" and afterwards `man` pages, `$PATH` or session vars look stale | `brew bundle` runs **before** home-manager in the activation script, so a non-zero exit aborts everything after it — the system profile advances but `/run/current-system` and `~/.zshenv` do not | fix the Homebrew error, re-run `just switch`. Confirm with `readlink /run/current-system` vs `readlink -f /nix/var/nix/profiles/system` — they must match |
| `Refusing to load … from untrusted tap` **only in an interactive shell** | trust lives in `$XDG_CONFIG_HOME/homebrew/trust.json` when that variable is set, but `nix-homebrew` writes it under `sudo` (env scrubbed) to `~/.homebrew/trust.json`. Activation reads the right one; your shell doesn't | harmless for activation. To silence it interactively: `env -u XDG_CONFIG_HOME brew …` |
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
- **Homebrew runtime (`brew-src`):** tracks Homebrew's `master` branch, so
  every `just update` moves the runtime together with the `homebrew-core` /
  `homebrew-cask` inputs; the exact commit is still locked in `flake.lock`. A
  fixed release tag drifted behind the taps twice, and too old a runtime rejects
  formulae outright (see the troubleshooting table above). If a new Homebrew
  ever breaks the switch, pin a tag in `flake.nix` until it is fixed.
- **Verify casks installed:** `brew list --cask | wc -l`.
