# macbookair: declarative macOS config

My entire Mac, reproducible from one repo: **nix-darwin + home-manager + flakes** on
**Determinate Nix**, pinned to stable **26.05**. Nix owns CLI tools, dotfiles, and macOS
settings; Homebrew (driven by nix-darwin) installs GUI casks + Mac App Store apps;
1Password handles secrets.

## Highlights
- **One command rebuilds the machine:** `nh darwin switch` (diff + confirm before activating).
- **Secrets stay out of git:** 1Password SSH agent + `op`; the repo holds only public keys and `op://` references, so it's safe to publish.
- **Signed, verified commits** with the 1Password SSH key.
- **Declarative macOS:** Dock, Finder, keyboard, fonts, screenshots, Touch-ID-for-sudo (works in tmux).
- **Controlled updates:** versions pinned in `flake.lock`; a weekly GitHub Action PRs lockfile bumps; GC and Nix upgrades are automatic (Determinate).

## Layout
| File | Owns |
|------|------|
| `flake.nix` | inputs + the `macbookair` system |
| `darwin.nix` | nix daemon, macOS defaults, hostname, Touch-ID sudo, fonts |
| `homebrew.nix` | 14 casks + 7 Mac App Store apps |
| `home.nix` | packages, zsh, starship, git/ssh, nh, direnv, dotfiles |
| `dotfiles/` | vendored ghostty, fastfetch, and nvim (LazyVim) configs |
| `starship.toml` | prompt (read via `fromTOML`) |
| `justfile` | `switch` / `update` / `check` / `rollback` |

## Usage
```sh
just switch    # apply config changes (diff + confirm)
just update    # bump flake.lock to latest, then switch
just check     # build without activating
just rollback  # revert to the previous generation
```

## Bootstrap (fresh machine)
1. Install [Determinate Nix](https://determinate.systems/) + 1Password (enable its SSH agent + CLI integration); sign into the App Store; turn on FileVault.
2. `git clone https://github.com/thisisgm/nix-config.git ~/nix-config && cd ~/nix-config`
3. Adopt any already-installed GUI apps into brew to avoid collisions: `brew install --cask --adopt google-chrome slack …`
4. First switch: `sudo nix run nix-darwin -- switch --flake .#macbookair` (renames host, installs everything). `just switch` thereafter.
5. Put machine-local SSH hosts in `~/.ssh/config.local` (gitignored).

## Notes
- **Not in nix (by design):** secrets (1Password) and a few App Store apps. The nvim config is vendored but symlinked out-of-store so it stays editable.
- **`cleanup = "zap"`** prunes anything undeclared; every app you keep must be listed in `casks` or `masApps`, or a switch removes it.
- A broken config fails at *build*, before activation; `just rollback` + Time Machine are the safety nets; Homebrew apps survive a full Nix uninstall.
