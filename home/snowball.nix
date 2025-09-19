{ ... }:
{
  imports = [
    ./features/desktop
    ./features/desktop/moneydance.nix
  ];

  slb = {
    isDesktop = true;
    enableDevelopment = true;
  };
}
