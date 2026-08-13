# Secrets

Managed with [sops-nix](https://github.com/Mic92/sops-nix) via its **home-manager**
module (wired in `modules/home/default.nix`, tooling in `modules/home/secrets.nix`).

Encrypted files in this directory **are committed**, deliberately. Nix flakes
only copy git-tracked files into the store, so an untracked secret is invisible
to `nix build` — which is exactly why a gitignored `local.nix` was never an
option. `.gitignore` therefore ignores everything here *except* `*.yaml` and
this README, so a stray plaintext file cannot be committed by accident.

## Key model

One age identity **per machine**, at `~/.config/sops/age/keys.txt`, created on
that machine and never copied:

```bash
age-keygen -o ~/.config/sops/age/keys.txt
```

Plus one **offline recovery identity** kept in the password manager and on no
machine, so losing a laptop never means losing access.

Adding a machine means adding its *public* key to `.sops.yaml` and re-encrypting
— no private material ever moves between machines:

```bash
sops updatekeys secrets/work.yaml
```

Deliberately **not** derived from SSH keys via `ssh-to-age`:
`~/.ssh/id_ed25519` is passphrase-protected, so nothing could decrypt unattended
at activation. A dedicated age key also survives SSH key rotation.

## Bootstrapping a new machine

Because a machine cannot decrypt until it is a recipient, and it cannot be a
recipient until its key exists, there is a one-time round-trip:

```
1. on the new machine   age-keygen -o ~/.config/sops/age/keys.txt
2. on the new machine   grep 'public key' ~/.config/sops/age/keys.txt
3. on beast             add that key to .sops.yaml, sops updatekeys, commit, push
4. on the new machine   git pull && just switch
```

Do **not** push a config that declares secrets before step 3 — sops-nix fails
activation when a declared secret cannot be decrypted, so the machine's next
switch would abort partway.

## Status

- **Stage 2A (done):** input, tooling, and the module — inert, nothing declared
- **Stage 2B:** keys, `.sops.yaml`, rehearsal secret on beast
- **Stage 2C:** work git identity and internal SSH hosts; `git.nix` / `ssh.nix`
  reference the decrypted paths and the hand-created files go away
