{ pkgs, ... }:
{
  # ── Nix daemon (Determinate module) ───────────────────────────────────────
  # determinateNix.enable sets nix.enable = false for us (Determinate owns the
  # daemon + /etc/nix/nix.conf). Caches + GC declared here instead of by hand.
  determinateNix = {
    enable = true;
    # Extra binary caches → written to /etc/nix/nix.custom.conf (the supported
    # override file; never edit /etc/nix/nix.conf directly).
    customSettings = {
      extra-substituters = [ "https://nix-community.cachix.org" ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    # Automatic, disk-pressure-based GC (default; here explicitly). No cron needed.
    determinateNixd.garbageCollector.strategy = "automatic";
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Workaround: pipx 1.8.0 on nixpkgs-26.05 ships stale package-specifier tests
  # (a `packaging` spacing change: 'black @ url' vs 'black@ url') that fail the
  # build. The tool itself is fine; skip its test suite. Drop this once upstream fixes it.
  nixpkgs.overlays = [
    (final: prev: {
      pipx = prev.pipx.overridePythonAttrs (_: {
        doCheck = false;
        doInstallCheck = false;
      });
    })
  ];

  # Required by current nix-darwin whenever homebrew or user-scoped
  # system.defaults are used (activation runs as root, needs an explicit user).
  system.primaryUser = "gm";

  # Backward-compat pin. Bare integer (NOT a string like NixOS). Leave as-is.
  system.stateVersion = 6;

  # ── Machine identity ──────────────────────────────────────────────────────
  networking.hostName = "macbookair";
  networking.computerName = "macbookair";
  networking.localHostName = "macbookair";

  # ── Security ──────────────────────────────────────────────────────────────
  # Touch ID (and Apple Watch) for sudo. Written to /etc/pam.d/sudo_local so it
  # survives macOS updates (the old enableSudoTouchIdAuth option was removed).
  # reattach = pam_reattach, so Touch ID works for sudo INSIDE tmux too.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # ── Fonts (system-wide so all GUI apps see them) ──────────────────────────
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # ── macOS defaults (audited + optimised 2026-06) ──────────────────────────
  system.defaults = {
    dock = {
      autohide = false;
      mineffect = "scale";
      minimize-to-application = true;
      show-recents = false;
      mru-spaces = false;
      launchanim = false;
      tilesize = 64;

      # Declarative Dock contents (captured order). Manual rearrange resets on switch.
      persistent-apps = [
        "/Applications/Google Chrome.app"
        "/System/Applications/Messages.app"
        "/Applications/WhatsApp.app"
        "/Applications/Discord.app"
        "/Applications/Notion.app"
        "/Applications/Slack.app"
        "/Applications/Claude.app"
        "/Applications/Ghostty.app"
        "/System/Applications/Mail.app"
        "/Applications/Proton Mail.app"
        "/System/Applications/App Store.app"
        "/System/Applications/System Settings.app"
      ];
      # Downloads with your exact view settings (else a plain path resets them):
      #   Sort by Date Added · Display as Folder · View content as List
      persistent-others = [
        {
          folder = {
            path = "/Users/gm/Downloads";
            arrangement = "date-added";
            displayas = "folder";
            showas = "list";
          };
        }
      ];
    };

    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXDefaultSearchScope = "SCcf";        # search current folder
      _FXSortFoldersFirst = true;
      FXEnableExtensionChangeWarning = false;
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv";         # list view
    };

    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;      # key repeat (for vim) instead of accent popup
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSNavPanelExpandedStateForSaveMode = true;
      AppleInterfaceStyle = "Dark";          # enum: only "Dark" exists; omit for light
      AppleShowAllExtensions = true;
      # autocapitalize / spell-correct / period-substitution intentionally left ON.
    };

    screencapture = {
      location = "/Users/gm/Pictures/Screenshots";   # dir created in home.nix activation
      disable-shadow = true;
      type = "png";
    };

    controlcenter.BatteryShowPercentage = true;

    WindowManager = {
      GloballyEnabled = false;                       # Stage Manager off
      EnableStandardClickToShowDesktop = false;      # don't show desktop on wallpaper click
    };
  };
}
