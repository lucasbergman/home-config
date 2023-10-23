{nixpkgs-unstable, ...}: {
  services.unifi = {
    enable = true;
    unifiPackage = nixpkgs-unstable.unifi7;
    # TODO: Consider setting initialJavaHeapSize and/or maximumJavaHeapSize
    # after doing some measurement
  };
}
