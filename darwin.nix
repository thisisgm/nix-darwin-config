{ pkgs, ... }:
{
  # Determinate owns the Nix daemon (sets nix.enable=false); caches + GC declared here.
  determinateNix = {
    enable = true;
    customSettings = {
      extra-substituters = [ "https://nix-community.cachix.org" ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    determinateNixd.garbageCollector.strategy = "automatic"; # disk-pressure GC, no cron
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  # pipx 1.8.0 on 26.05 ships stale tests that fail the build; tool's fine, skip them.
  nixpkgs.overlays = [
    (final: prev: {
      pipx = prev.pipx.overridePythonAttrs (_: {
        doCheck = false;
        doInstallCheck = false;
      });
    })
  ];

  system.primaryUser = "gm"; # required once homebrew / user defaults are set
  system.stateVersion = 6; # compat pin (bare int); leave as-is

  networking.hostName = "macbookair";
  networking.computerName = "macbookair";
  networking.localHostName = "macbookair";

  # Touch ID for sudo, incl. inside tmux (pam_reattach); survives macOS updates.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ]; # system-wide so GUI apps see it

  system.defaults = {
    dock = {
      autohide = false;
      mineffect = "scale";
      minimize-to-application = true;
      show-recents = false;
      mru-spaces = false;
      launchanim = false;
      tilesize = 64;

      # Pinned apps in order (manual rearrange resets on the next switch).
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
      # Downloads stack: Date Added / Folder / List.
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
      FXDefaultSearchScope = "SCcf"; # search current folder
      _FXSortFoldersFirst = true;
      FXEnableExtensionChangeWarning = false;
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv"; # list view
    };

    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false; # key repeat instead of accent popup
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSNavPanelExpandedStateForSaveMode = true;
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
    };

    screencapture = {
      location = "/Users/gm/Pictures/Screenshots"; # dir created in home.nix
      disable-shadow = true;
      type = "png";
    };

    controlcenter.BatteryShowPercentage = true;

    WindowManager = {
      GloballyEnabled = false; # Stage Manager off
      EnableStandardClickToShowDesktop = false;
    };
  };
}
