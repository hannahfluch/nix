{
  config,
  lib,
  pkgs,
  ...
}:
{

  # settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # new generation
  system.rebuild.enableNg = true;

  # disable nix channels
  nix.channel.enable = false;

  # systemd bootloader
  boot.loader.systemd-boot.enable = true;

  # networking
  networking.hostName = "chicken";
  # Pick only one of the below networking options.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # time zone
  time.timeZone = "Europe/Vienna";

  # internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de-latin1";
    # useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable upower
  services.upower.enable = true;

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  # Better performance
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Enable keyring storage
  services.gnome.gnome-keyring.enable = true;

  # age secrets
  # agenix runs BEFORE impermanence
  age.identityPaths = [ "/persistent/data/home/hannah/nixcfg/keys/id_ed25519" ];

  # user accounts
  users.mutableUsers = false;
  users.users.hannah = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.passwd.path;
    extraGroups = [
      "wheel"
      "video"
      "wireshark"
      "networkmanager"
    ]; # Enable ‘sudo’ for the user.
    packages = [ ];
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    wireshark
  ];

  # Display Manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${lib.getExe pkgs.greetd.tuigreet} --time --remember --remember-session";
        user = "greeter";
      };
    };
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  virtualisation =
    let
      options = {
        virtualisation.memorySize = 8192;
        virtualisation.graphics = true;
        virtualisation.cores = 6;
      };
    in
    {
      docker.enable = true;
      podman.enable = true;
      vmVariant = options;
      vmVariantWithDisko = options;
    };

  # System-wide installation to make it recogizable by the display manager
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  # Install wireshark + adds wireshark group
  programs.wireshark = {
    enable = true;
    # capture usb traffic
    usbmon.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Show battery charge of Bluetooth devices
        ControllerMode = "bredr";
      };
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
