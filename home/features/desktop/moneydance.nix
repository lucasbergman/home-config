{mypkgs, ...}: {
  home.packages = [
    (mypkgs.moneydance.override {jvmFlags = ["-Dsun.java2d.uiScale=2"];})
  ];
}
