# copied from nixpkgs
{ lib, stdenvNoCC, requireFile, autoPatchelfHook, makeWrapper, alsa-lib, dbus
, expat, fontconfig, glib, libdrm, libglvnd, libpulseaudio, libudev0-shim
, libxkbcommon, libxml2, libxslt, nspr, wayland, nss, xorg, dpkg, unixtools
, buildFHSEnv, copyDesktopItems, makeDesktopItem, fetchFromGitHub
, version ? "8.2.2", packetTracerSource ? null }:
let
  hashes = {
    "8.2.0" = "sha256-GxmIXVn2Ew7lVBT7AuIRoXc0YGids4v9Gsfw1FEX7RY=";
    "8.2.1" = "sha256-QoM4rDKkdNTJ6TBDPCAs+l17JLnspQFlly9B60hOB7o=";
    "8.2.2" = "sha256-bNK4iR35LSyti2/cR0gPwIneCFxPP+leuA1UUKKn9y0=";
  };
  names = {
    "8.2.0" = "CiscoPacketTracer_820_Ubuntu_64bit.deb";
    "8.2.1" = "CiscoPacketTracer_821_Ubuntu_64bit.deb";
    "8.2.2" = "CiscoPacketTracer822_amd64_signed.deb";
  };

  unwrapped = stdenvNoCC.mkDerivation {
    name = "packetTracer-unwrapped";
    inherit version;

    src = if (packetTracerSource != null) then
      packetTracerSource
    else
      requireFile {
        name = names.${version};
        hash = hashes.${version};
        url = "https://www.netacad.com";
      };

    buildInputs = [
      autoPatchelfHook
      makeWrapper
      alsa-lib
      dbus
      expat
      fontconfig
      glib
      libdrm
      libglvnd
      libpulseaudio
      libudev0-shim
      libxkbcommon
      libxml2
      libxslt
      nspr
      nss
      wayland
    ] ++ (with xorg; [
      libICE
      libSM
      libX11
      libXScrnSaver
      libXcomposite
      libXcursor
      libXdamage
      libXext
      libXfixes
      libXi
      libXrandr
      libXrender
      libXtst
      libxcb
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilwm
    ]);

    nativeBuildInputs = [ unixtools.xxd ];

    patchPhase = ''
      source ${
        fetchFromGitHub {
          owner = "hannahfluch";
          repo = "patchpt";
          tag = "v0.1.0";
          hash = "sha256-2eQ+3z6f2KkxWeRbvu+1QR/ZN/31LfEcPIDce5eUUD8=";
        }
      }/patch.sh "$out/opt/pt/bin/PacketTracer"
    '';

    unpackPhase = ''
      runHook preUnpack

      ${lib.getExe' dpkg "dpkg-deb"} -x $src $out
      chmod 755 "$out"

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      makeWrapper "$out/opt/pt/bin/PacketTracer" "$out/bin/packettracer8" \
        --prefix LD_LIBRARY_PATH : "$out/opt/pt/bin"

      runHook postInstall
    '';
  };

  fhs-env = buildFHSEnv {
    name = "packetTracer-fhs-env";
    runScript = lib.getExe' unwrapped "packettracer8";
    targetPkgs = _: [ libudev0-shim ];
  };
in stdenvNoCC.mkDerivation {
  pname = "packetTracer";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [ copyDesktopItems ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ln -s ${fhs-env}/bin/${fhs-env.name} $out/bin/packettracer8

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "cisco-pt";
      desktopName = "Packet Tracer";
      icon = "${unwrapped}/opt/pt/art/app.png";

      exec = "packettracer8 %u";
      mimeTypes = [
        "x-scheme-handler/pttp" # patch: enable pttp protocol
        "application/x-pkt"
        "application/x-pka"
        "application/x-pkz"
      ];
    })
  ];

  meta = {
    description = "Network simulation tool from Cisco";
    homepage = "https://www.netacad.com/courses/packet-tracer";
    license = lib.licenses.unfree;
    mainProgram = "packettracer8";
    maintainers = with lib.maintainers; [ gepbird ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
