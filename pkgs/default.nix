{pkgs}: {
  cat-gcp-secret = pkgs.callPackage ./cat-gcp-secret {};
  gcp-secret-subst = pkgs.callPackage ./gcp-secret-subst {};
}
