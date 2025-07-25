{ pkgs, ... }:
{
  home.packages = [
    (pkgs.vesktop.overrideAttrs (
      finalAttrs: previousAttrs: {
        postUnpack = ''
          cp ${../../assets/custom_vesktop.gif} $sourceRoot/static/shiggy.gif

          ${previousAttrs.postUnpack or ""}

        '';
      }
    ))
  ];
  persist.data.contents = [ ".config/vesktop/" ];
}
