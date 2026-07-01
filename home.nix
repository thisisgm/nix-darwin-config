{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Personal ed25519 public key (1Password holds the private half); used for
  # commit signing and GitHub ssh auth.
  gmPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzFQh0nnBHOEBWajMx0+etRRivHNsa+B0LJ6BTaZzRM";
in
{
  home.username = "gm";
  home.homeDirectory = "/Users/gm";
  home.stateVersion = "26.05"; # matches home-manager release; don't bump on upgrade

  # CLI packages (fzf/zoxide/starship/git + zsh plugins come from programs.* below).
  home.packages = with pkgs; [
    duti
    fastfetch
    ffmpeg
    gh
    mtr
    neovim # config vendored in dotfiles/nvim (symlinked below)
    nodejs
    openvpn
    oxipng
    pipx
    pyenv
    shellcheck
    sox
    sshpass
    tmux
    wireguard-tools
    ripgrep
    fd
    lazygit
    pet # snippet manager (zsh Ctrl+S below)
    just
    expect # for the scripted ssh helper scripts
  ];

  # PATH for self-managed tools (uv, opencode, pipx).
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.opencode/bin"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Custom bits no module covers: login banner, pet, transient prompt.
    initContent = ''
      if [[ -o interactive && -t 1 ]] && command -v fastfetch >/dev/null; then
        fastfetch
      fi

      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'

      # pet (Ctrl+S: search snippets into the buffer)
      function pet-select() {
        BUFFER=$(pet search --query "$LBUFFER")
        CURSOR=$#BUFFER
        zle redisplay
      }
      zle -N pet-select
      stty -ixon
      bindkey '^s' pet-select
      function pet-prev() {
        PREV=$(fc -lrn | head -n 1)
        sh -c "pet new $(printf %q "$PREV")"
      }

      # transient prompt: collapse finished prompts to a bare ❯
      autoload -Uz add-zle-hook-widget
      function _collapse_prompt() {
        PROMPT='%F{#9ece6a}❯%f '
        RPROMPT=""
        zle .reset-prompt
      }
      add-zle-hook-widget line-finish _collapse_prompt
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    # SSH commit signing via 1Password (op-ssh-sign).
    signing = {
      format = "ssh";
      key = gmPubKey;
      signByDefault = true;
      signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };
    settings = {
      user.name = "Gianmarco Morales";
      user.email = "gianmarcomorales@icloud.com";
      init.defaultBranch = "main";
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.config/git/allowed_signers";
      # Pushes to GitHub go over SSH via the 1Password agent (no https token
      # helper). Fetches keep anonymous https so plugin managers still work
      # with 1Password locked; private repos clone via ssh:// (gh uses ssh).
      url."ssh://git@github.com/".pushInsteadOf = "https://github.com/";
      url."ssh://git@gist.github.com/".pushInsteadOf = "https://gist.github.com/";
    };
  };

  # Nicer rebuilds: diff-preview + confirm before activating.
  programs.nh = {
    enable = true;
    flake = "/Users/gm/nix-darwin-config";
  };

  # Fast cached per-project dev environments.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Generic config in-repo; machine-local hosts live in gitignored ~/.ssh/config.local.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "~/.ssh/config.local" ];
    settings."*" = {
      IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
      ControlMaster = "auto";
      ControlPath = "~/.ssh/sockets/%C";
      ControlPersist = "10m";
      ServerAliveInterval = 30;
      ServerAliveCountMax = 6;
      TCPKeepAlive = "yes";
    };
    # Pin the personal key for github.com so the agent never offers another
    # account's key first; work github goes through an alias in config.local.
    settings."github.com" = {
      IdentitiesOnly = "yes";
      IdentityFile = "~/.ssh/github-thisisgm.pub";
    };
  };

  # Public half of the pinned GitHub auth key (private half stays in 1Password).
  home.file.".ssh/github-thisisgm.pub".text = "${gmPubKey}\n";

  # Vendored configs. Ghostty → Application Support (that path wins over ~/.config on macOS).
  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    ./dotfiles/ghostty/config;
  xdg.configFile."fastfetch/config.jsonc".source = ./dotfiles/fastfetch/config.jsonc;

  # Touch-ID 1Password sudo autofill for Ghostty (bound to a hotkey by skhd in darwin.nix).
  # The 1Password item ref stays machine-local in ~/.config/ghostty-sudo-fill.env.
  home.file.".local/bin/ghostty-sudo-fill" = {
    source = ./dotfiles/ghostty-sudo-fill.sh;
    executable = true;
  };

  # nvim (LazyVim): out-of-store symlink so it stays editable and lazy.nvim can write lazy-lock.json.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-darwin-config/dotfiles/nvim";

  # Local verification of my ssh-signed commits.
  home.file.".config/git/allowed_signers".text = "gianmarcomorales@icloud.com ${gmPubKey}\n";

  # Ensure runtime dirs exist.
  home.activation.mkRuntimeDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD /bin/mkdir -p "$HOME/Pictures/Screenshots" "$HOME/.ssh/sockets"
  '';
}
