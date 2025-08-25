{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # cli essentails
    wl-clipboard
    fd
    ripgrep
    fastfetch
    tokei
    tlrc
    screen
    docker
    docker-compose
    podman
    podman-compose
    unp
    file
    man-pages
    man-pages-posix
    traceroute
    bottom
    zellij

    # ctf
    hash_extender
    qemu
    gdb
    volatility3
    rubyPackages_3_4.seccomp-tools
    nmap
    metasploit
  ];

  services.podman.enable = true;
  persist.data.contents = [
    # podman containers & config
    ".local/share/containers/storage/"
  ];
  persist.caches.contents = [
    # podman
    ".local/share/containers/cache/"
  ];
}
