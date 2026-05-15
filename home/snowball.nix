{ mypkgs, ... }:
{
  home.packages = [
    mypkgs.google-antigravity-cli
    mypkgs.google-antigravity-ide
  ];

  slb = {
    isDesktop = true;
    enableDevelopment = true;
    notmuch = {
      enable = true;
      primaryMailAccount = "bergmans";
    };
  };
}
