{ mypkgs, ... }:
{
  home.packages = [
    (mypkgs.moneydance.override {
      jvmFlags = [
        "-Dawt.useSystemAAFontSettings=on"
      ];
    })
  ];
}
