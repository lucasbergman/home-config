{
  mypkgs,
  nixpkgs,
  ...
}: {
  imports = [
    ../../../common/unifi.nix

    ./monitoring.nix
    ./plex.nix
  ];

  slb.unifi = {
    enable = true;
    unifiPackage = mypkgs.unifi;
    jrePackage = nixpkgs.jdk11;
    # TODO: Consider setting initialJavaHeapSize and/or maximumJavaHeapSize
    # after doing some measurement
  };
}
