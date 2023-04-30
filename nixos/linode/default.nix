{...}: {
  imports = [./boot.nix];

  networking = {
    usePredictableInterfaceNames = false;
    useDHCP = false;
    networkmanager.enable = true;
  };
}
