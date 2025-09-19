{ ... }:
{
  imports = [
    ./features/desktop
    ./features/desktop/moneydance.nix
    ./features/development
  ];

  slb = {
    isDesktop = true;
    enableDevelopment = true;
  };
}
