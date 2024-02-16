{inputs, ...}: {
  imports = [
    inputs.vscode-server.homeModules.default

    ./global
    ./features/vscode-server.nix
  ];
}
