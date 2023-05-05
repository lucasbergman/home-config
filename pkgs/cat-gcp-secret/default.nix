{pkgs, ...}:
pkgs.buildGoApplication {
  pname = "cat-gcp-secret";
  version = "0.1";
  pwd = ./.;
  src = ./.;
  go = pkgs.go;
}
