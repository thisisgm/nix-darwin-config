{ pkgs, config, lib, ... }:
{
  home.username = "gm";
  home.homeDirectory = "/Users/gm";
  home.stateVersion = "26.05";   # matches home-manager release; do not bump on upgrade

  # ── CLI packages ──────────────────────────────────────────────────────────
  # (fzf, zoxide, starship, git, and the zsh plugins are provided by programs.*
  #  modules below — not listed here, to avoid double-install.)
  home.packages = with pkgs; [
    duti              # set default URL/file handlers (used by ssh-handler)
    fastfetch         # login banner (config below)
    ffmpeg
    gh                # also backs the git credential helper
    mtr
    neovim            # config = existing ~/.config/nvim (LazyVim), left writable
    nodejs            # `node`/`npm` (nodejs_24)
    openvpn
    oxipng
    pipx
    pyenv
    shellcheck
    sox
    sshpass
    tmux
    wireguard-tools
    # added for LazyVim + workflow
    ripgrep
    fd
    lazygit
    pet               # snippet manager (zsh Ctrl+S integration below)
    just              # task runner (see justfile)
    expect            # scripted ssh helpers (was system /usr/bin/expect)
  ];

  # PATH additions for self-managed tools (uv, opencode, pipx)
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.opencode/bin"
  ];

  # ── zsh ───────────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;         # (new name; old enableAutosuggestions removed)
    syntaxHighlighting.enable = true;     # sourced last by home-manager automatically

    # Everything from your old ~/.zshrc that isn't handled by a module.
    # No `${` sequences here, so the nix '' string needs no escaping.
    initContent = ''
      # System-info banner on new interactive shell (replaces "Last login")
      if [[ -o interactive && -t 1 ]] && command -v fastfetch >/dev/null; then
        fastfetch
      fi

      # zsh-autosuggestions: gray ghost text (tokyonight comment color)
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'

      # ── Pet snippet manager ─────────────────────────────────────────────
      # Ctrl+S: search snippets into the current buffer
      function pet-select() {
        BUFFER=$(pet search --query "$LBUFFER")
        CURSOR=$#BUFFER
        zle redisplay
      }
      zle -N pet-select
      stty -ixon
      bindkey '^s' pet-select
      # register the previous command as a snippet
      function pet-prev() {
        PREV=$(fc -lrn | head -n 1)
        sh -c "pet new $(printf %q "$PREV")"
      }

      # Transient prompt: collapse finished prompts to a bare ❯ (clean scrollback).
      # add-zle-hook-widget appends, so it coexists with syntax-highlighting's hooks.
      autoload -Uz add-zle-hook-widget
      function _collapse_prompt() {
        PROMPT='%F{#9ece6a}❯%f '
        RPROMPT=""
        zle .reset-prompt
      }
      add-zle-hook-widget line-finish _collapse_prompt
    '';
  };

  # ── prompt / shell tools (integration auto-wired into zsh) ────────────────
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;   # Ctrl-R history, Ctrl-T files, Alt-C cd
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── git ───────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    # SSH commit signing via 1Password — structured signing.* maps to
    # user.signingKey / gpg.format / gpg.ssh.program / commit.gpgSign.
    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzFQh0nnBHOEBWajMx0+etRRivHNsa+B0LJ6BTaZzRM";
      signByDefault = true;
      signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };
    # rfc42 `settings` form (userName/userEmail/extraConfig were deprecated).
    settings = {
      user.name = "Gianmarco Morales";
      user.email = "gianmarcomorales@icloud.com";
      init.defaultBranch = "main";
      # local verification of ssh-signed commits (GitHub verifies independently)
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.config/git/allowed_signers";

      # gh as credential helper. PATH-relative (NOT /opt/homebrew/...) so it
      # survives the brew->nix move. Empty first entry resets inherited helpers.
      credential."https://github.com".helper = [ "" "!gh auth git-credential" ];
      credential."https://gist.github.com".helper = [ "" "!gh auth git-credential" ];
    };
  };

  # ── nh (nicer darwin rebuilds: diff-preview + confirm before activating) ───
  programs.nh = {
    enable = true;
    flake = "/Users/gm/nix-config";   # sets NH_FLAKE → `nh darwin switch` needs no path
    # No clean.enable — Determinate Nixd already auto-GCs (avoid double-scheduling).
  };

  # ── direnv + nix-direnv (fast cached per-project flake/nix environments) ───
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ── ssh ───────────────────────────────────────────────────────────────────
  # Public-safe generic config here; work hosts (bastion/IPs) live in the
  # gitignored ~/.ssh/config.local (Included below). Keys served by 1Password agent.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;            # opt out of the soon-to-be-removed Host * defaults
    includes = [ "~/.ssh/config.local" ];
    settings = {
      "*" = {
        IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
        ControlMaster = "auto";
        ControlPath = "~/.ssh/sockets/%C";
        ControlPersist = "10m";
        ServerAliveInterval = 30;
        ServerAliveCountMax = 6;
        TCPKeepAlive = "yes";
      };
    };
  };

  # ── vendored dotfiles (pinned in-repo) ────────────────────────────────────
  # Ghostty: write straight into Application Support so it can't be shadowed by a
  # stale copy there (that path wins over ~/.config on macOS).
  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    ./dotfiles/ghostty/config;

  xdg.configFile."fastfetch/config.jsonc".source =
    ./dotfiles/fastfetch/config.jsonc;

  # allowed-signers for verifying your own ssh-signed commits locally
  home.file.".config/git/allowed_signers".text =
    "gianmarcomorales@icloud.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzFQh0nnBHOEBWajMx0+etRRivHNsa+B0LJ6BTaZzRM\n";

  # ── activation: ensure runtime dirs exist ─────────────────────────────────
  home.activation.mkRuntimeDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD /bin/mkdir -p "$HOME/Pictures/Screenshots" "$HOME/.ssh/sockets"
  '';
}
