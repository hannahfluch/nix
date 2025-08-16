{ pkgs, ... }:
{
  imports = [
    ./xdg.nix
    ./terminal
    ./hyprland
    ./fuzzel.nix
    ./ssh.nix
    ./git.nix
    ./agenix.nix
    ./applications
    ./toolchains
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = rec {
    username = "hannah";
    homeDirectory = "/home/${username}";

    packages = with pkgs; [
      # fonts
      meslo-lgs-nf

      # apps
      # gimp
      # teams-for-linux
      # packetTracer
      # nautilus
      # hyprlock
      # mysql workbench

      # prismlauncher
      # steam
      # vlc

    ];

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "25.05";
  };

  persist.data.contents = [
    # user data
    "music/"
    "pictures/"
    "documents/"
    "videos/"
    "dev/"
    ".secrets/"

    # nixos config
    "nixcfg/"
  ];

  persist.caches.contents = [
    ".cache/"
  ];
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
