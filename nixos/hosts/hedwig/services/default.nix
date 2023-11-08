{
  mypkgs,
  nixpkgs,
  ...
}: {
  imports = [
    ./monitoring.nix
    ./plex.nix
  ];

  services.unifi = {
    enable = true;
    unifiPackage = mypkgs.unifi;
    jrePackage = nixpkgs.jdk11;
    # TODO: Consider setting initialJavaHeapSize and/or maximumJavaHeapSize
    # after doing some measurement
  };
}
