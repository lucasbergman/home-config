{ vscode-server, ... }:
{
  imports = [
    vscode-server.homeModules.default
  ];

  slb = {
    isDesktop = false;
    enableDevelopment = true;
  };
}
