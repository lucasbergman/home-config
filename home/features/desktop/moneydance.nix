{ pkgs, ... }:
let
  # Since I maintain Moneydance in nixpkgs, I mess with different versions all the time
  pinnedMoneydance = pkgs.moneydance.overrideAttrs (prev: {
    version = "2024.4_5253";
    src = pkgs.fetchzip {
      url = "https://infinitekind.com/stabledl/2024.4.5253/moneydance-linux.tar.gz";
      hash = "sha256-xOdkuaN17ss9tTSXgU//s6cBm2jGEgP9eTtvW0k3VWQ=";
    };
  });
in
{
  home.packages = [
    (pinnedMoneydance.override { jvmFlags = [ "-Dawt.useSystemAAFontSettings=on" ]; })
  ];
}
