{
  nixpkgs,
  nixpkgs-unstable,
  ...
}: {
  services.unifi = {
    enable = true;
    unifiPackage = nixpkgs-unstable.unifiCustomPackage;
    jrePackage = nixpkgs.jdk8;
    # TODO: Consider setting initialJavaHeapSize and/or maximumJavaHeapSize
    # after doing some measurement
  };
}