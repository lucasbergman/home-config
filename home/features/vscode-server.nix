{pkgs, ...}: {
  services.vscode-server = {
    enable = true;
    nodejsPackage = pkgs.nodejs-18_x;
  };
}
