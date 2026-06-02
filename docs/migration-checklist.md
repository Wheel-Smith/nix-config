# Migration Checklist

Before real machine switch:

```bash
brew leaves > docs/current-brew-leaves.txt
brew list --cask > docs/current-brew-casks.txt
mas list > docs/current-mas-list.txt
mkdir -p ~/dotfiles-backup-before-nix
cp -R ~/.zshrc ~/.gitconfig ~/.config ~/dotfiles-backup-before-nix/ 2>/dev/null || true
```
