# Post-install checklist

These are intentionally manual. They are app-owned, account-owned, privacy/TCC, or consent-gated settings that are more reliable as explicit setup steps than as brittle activation scripts.

## Browser and launcher

- Open System Settings → Desktop & Dock → Default web browser → Brave Browser.
- Open Raycast once and set its hotkey to Cmd-Space.
- Verify Option-Cmd-Space still opens Finder search.
- If Cmd-Space opens Spotlight instead of Raycast, confirm the nix-darwin symbolic hotkey setting for Spotlight hotkey 64 is active, then restart SystemUIServer or log out/in.

## Accounts and sync

Sign in manually where needed:

- iCloud / Apple ID
- Proton Pass
- Proton Mail
- Proton Drive
- Tailscale
- NordVPN / ProtonVPN
- Slack
- Telegram
- WhatsApp
- Spotify
- Obsidian Sync, if used
- Browser sync

## Privacy & Security permissions

Grant permissions only when macOS prompts or when an app clearly needs them.

Likely permissions:

- Raycast: Accessibility, Automation as prompted
- AeroSpace: Accessibility
- Shottr: Screen Recording, Accessibility if needed
- RustDesk: Screen Recording, Accessibility, Full Disk Access as needed
- Ghostty: Developer tools / local network prompts only if needed
- Orbstack: privileged helper/network prompts as prompted
- Tailscale/VPN apps: VPN configuration approval

## Security setup

- Enroll Touch ID in System Settings.
- Confirm Touch ID works for sudo after nix-darwin switch.
- Enable FileVault manually after the VM-tested config is stable on real hardware.
- Confirm recovery key storage before relying on FileVault.

## SSH keys

Nix manages `~/.ssh/config`, but not private keys.

Recommended manual setup:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "$(id -un)@$(scutil --get LocalHostName)" -f ~/.ssh/id_ed25519
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Add the public key to GitHub:

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

Then verify:

```bash
ssh -T git@github.com
```

## Screenshots

Nix sets screenshots to:

```text
~/Pictures/Screenshots
```

Verify after rebuild:

```bash
defaults read com.apple.screencapture location
defaults read com.apple.screencapture type
```

## Final verification

From the repo:

```bash
just doctor
```

