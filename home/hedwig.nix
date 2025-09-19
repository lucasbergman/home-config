{ vscode-server, ... }:
{
  imports = [
    vscode-server.homeModules.default
    ./features/vscode-server.nix
  ];

  slb = {
    isDesktop = false;
    enableDevelopment = true;
  };
}
