{ mypkgs, pkgs, ... }:
{
  home.packages = [
    (mypkgs.moneydance.override {
      clientJdk = pkgs.jetbrains.jdk;
      baseJvmFlags = [ "-client" ];
      jvmFlags = [ "-Dawt.toolkit.name=WLToolkit" ];
    })
  ];
}
