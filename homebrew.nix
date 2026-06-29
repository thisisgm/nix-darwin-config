{ ... }:
{
  # GUI + Mac App Store apps; the list is declarative, brew/mas do the install.
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # "zap" deletes anything undeclared (incl. App Store apps not in masApps); declare every app you keep.
      cleanup = "zap";
    };

    casks = [
      "google-chrome"
      "whatsapp"
      "discord"
      "notion"
      "slack"
      "claude"
      "proton-mail"
      "ghostty"
      "tailscale-app" # GUI cask (`tailscale` is the CLI formula)
      "adguard"
      "cyberduck"
      "keka"
      "1password"
      "1password-cli"
    ];

    # App Store apps (name = numeric ID).
    masApps = {
      "Infuse" = 1136220934;
      "Amperfy" = 1530145038;
      "Parcel" = 375589283;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Termius" = 1176074088;
    };
  };
}
