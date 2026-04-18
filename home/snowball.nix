{ mypkgs, ... }:
{
  home.packages = [ mypkgs.google-antigravity ];

  slb = {
    isDesktop = true;
    enableDevelopment = true;
    notmuch = {
      enable = true;
      primaryMailAccount = "bergmans";
    };
  };
}
