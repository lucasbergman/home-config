{pkgs, ...}:
pkgs.buildGoApplication {
  pname = "gcp-secret-subst";
  version = "0.1";
  pwd = ./.;
  src = ./.;
  go = pkgs.go;
}
