# VM Testing

## What a VM can and cannot prove

A stock UTM macOS VM is **not** Intune-enrolled, **not** supervised, has no
config profiles, and no Defender. So be clear about what you are buying:

| A VM **does** prove | A VM **cannot** prove |
|---|---|
| The flake evaluates and activates on a clean machine | Activation survives a profile-locked setting |
| Every `system.defaults` write lands correctly | Whether Intune reverts the machine name |
| Homebrew installs and the cask set is right | Defender's scanning cost on `/nix/store` |
| Colima, `docker compose`, git identities, symlinks | `dscl` behaviour on a Platform-SSO account |
| Rollback works | That OneDrive's real tenant folder is globbed right |

**Run the VM on the work MacBook, not on `beast`.** That is the single highest-
value thing you can do here: the VM inherits the corporate network, so it tests
whether the Determinate Nix installer and Homebrew downloads survive any
proxying or TLS interception. That failure mode hits *before* any of this config
runs, and it is invisible from a home network.

## VM setup

1. UTM → **Virtualize** → macOS 26 (an Apple Silicon macOS VM needs an IPSW).
2. Give it **80 GB+** — `/nix` plus 13 casks is not small.
3. During Setup Assistant, create the account with short name **`kristjan`**.
   This matters: the config hardcodes that username, and `just` detects the host
   from `id -un`. Skip the Apple ID (macOS VMs cannot use iCloud anyway, which
   happens to match the work Mac's configuration).
4. Name the machine **`vm-test`** in Setup Assistant. Nix will not touch
   it — `.#work` sets no `networking.*`, exactly as on the real work Mac where
   Intune owns the name. Setting it by hand here mirrors that: the name comes
   from outside the config, and `just verify` reports it rather than asserting
   it.
5. **Snapshot the VM now**, before installing anything, so you can re-run the
   whole activation from clean.

## Run

```bash
xcode-select --install
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
# open a new terminal

git clone https://github.com/Wheel-Smith/nix-config.git ~/projects/nix-config
cd ~/projects/nix-config
sudo nix run nix-darwin -- switch --flake .#work
```

Expect the first switch to take a while: Homebrew plus a dozen casks is several
GB.

## Verify

```bash
just verify
```

`scripts/verify-host.sh` asserts ~30 properties, including the negative ones
that are easy to get wrong — that the Spotlight hotkey is *still* bound, that
`power.sleep` was *not* applied, that `mas` is *absent*, that no excluded cask
snuck in, and that git *refuses* to commit outside `~/work` and `~/projects`.

It exits non-zero on any failure. On `beast` today it reports 16/16.

Some checks will legitimately SKIP in a VM. To exercise them too:

```bash
# 1. Fake a OneDrive tenant folder, then re-run switch
mkdir -p ~/Library/CloudStorage/OneDrive-TestOrg
just switch && ls -la ~/onedrive

# 2. Create the two hand-made identity files (setup steps 3 and 4 in work-mac.md)
mkdir -p ~/.config/git
printf '[user]\n\tname = Test\n\temail = test@example.com\n' > ~/.config/git/work.inc
touch ~/.ssh/config.local && chmod 600 ~/.ssh/config.local

just verify   # the two SKIPs should now PASS
```

## Also worth exercising by hand

```bash
# Idempotence — a second switch must be a no-op, not an error
sudo darwin-rebuild switch --flake .#work

# Rollback actually works
darwin-rebuild --list-generations
sudo darwin-rebuild rollback
just verify          # should now FAIL — that is correct, you rolled back
sudo darwin-rebuild switch --flake .#work

# Containers really run, not just install
colima start && docker run --rm hello-world && docker compose version

# Aerospace: grant Accessibility when prompted, then
aerospace list-workspaces --all
```

And confirm Nix left the machine name alone — it should still be whatever you
typed in Setup Assistant, not anything from the config:

```bash
scutil --get ComputerName    # vm-test, unchanged by any switch
```

## After the VM passes

The VM has validated the configuration. What remains untested on the real
machine is only the managed-Mac surface: profile conflicts, Defender, and the
corporate network — and if you ran the VM on the work MacBook, the network part
is covered too.

Run the pre-flight check first, since the real machine is not fresh:

```bash
./scripts/preflight.sh work
```

Then activate and confirm:

```bash
sudo nix run nix-darwin -- switch --flake .#work
```

```bash
just verify
```

`sudo darwin-rebuild rollback` is your net from the second generation onwards.
