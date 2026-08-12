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

Both hosts are `aarch64-darwin` (Apple Silicon), with Homebrew pinned via
`nix-homebrew` (tap-trust aware, Golden Gate-ready).

`just` picks the host automatically from `id -un`, so `just switch` means the
right thing on either machine.

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

> Bootstrapping the **work** Mac is different — it needs hand-created identity
> files, fresh SSH keys, and a staged activation. Follow
> [`docs/work-mac.md`](docs/work-mac.md) instead of this section.

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
├── flake.nix                    # inputs, host definitions, nix-homebrew + tap trust
├── flake.lock                   # pinned dependency revisions (commit this!)
├── hosts/
│   ├── beast/                   # personal: dock, homebrew, packages + firewall/hostname
│   └── work/                    # work: dock, homebrew, packages (no firewall/hostname)
├── scripts/                     # preflight.sh (before switch), verify-host.sh (after)
└── modules/
    ├── darwin/                  # default.nix = the set safe on EVERY host
    ├── home/                    # home-manager; gated by isWork where hosts differ
    └── shared/
```

Hosts share code through an `isWork` flag threaded via `specialArgs`:

- **Identical on both** — `nix`, `system`, `finder`, `trackpad`, `keyboard`,
  `screenshots`, `fonts`, `security`, and all the shell/editor modules.
- **Shared, forked internally by `isWork`** — `preferences.nix`,
  `aerospace.nix`, `packages.nix`, `git.nix`, `ssh.nix`, `links.nix`,
  `vscode.nix`, `containers.nix`.
- **Per-host files** — `dock.nix`, `homebrew.nix`, `packages.nix` under
  `hosts/<host>/`.
- **`beast`-only imports** — `firewall.nix`, `hostname.nix`. These are
  compliance controls that the MDM owns on the work Mac; see
  [`docs/work-mac.md`](docs/work-mac.md) for why importing them there can hard-fail
  activation.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `The option 'nix-homebrew.trust' does not exist` | `flake.lock` pins a `nix-homebrew` commit older than the tap-trust feature (PR #157) | `just update-input nix-homebrew` |
| `nixos-render-docs: error: unrecognized arguments: --sidebar-depth` | `nix-darwin` is newer than `nixpkgs` | `just update-input nixpkgs` (keep them in sync). Temporary bypass: `documentation.enable = false;` |
| `Homebrew requires formulae to be in a tap, rejecting` | Old `nix-homebrew` rejecting `/nix/store`-backed taps (issue #148) | `just update-input nix-homebrew` (needs the PR #150 fix) |
| `unknown keyword: :overwrite` (or any *"formula is unreadable"*), then `brew bundle can't satisfy your Brewfile` | `brew-src` runtime older than the `homebrew-core`/`homebrew-cask` inputs, which have adopted a newer DSL | bump `inputs.brew-src.url` in `flake.nix` to the current Homebrew tag |
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
- **`brew-src` pin:** currently `6.0.17`. The floor is macOS 27 support (first
  in the 6.0.11 line), but the pin must also stay **at least as new as the
  `homebrew-core` / `homebrew-cask` inputs**, which move independently and adopt
  new DSL keywords over time. Too old a runtime rejects formulae outright — see
  the troubleshooting row below.
- **Verify casks installed:** `brew list --cask | wc -l`.
