{ vscode-server, ... }:
{
  imports = [
    vscode-server.homeModules.default

    ./global
    ./features/vscode-server.nix
  ];
}
