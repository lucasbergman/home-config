{ pkgs, pkgs-unstable, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscode;
    profiles.default.extensions = with pkgs-unstable.vscode-extensions; [
      bbenoist.nix
      ms-python.debugpy
      ms-python.mypy-type-checker
      ms-python.python
      ms-vscode-remote.remote-ssh
    ];
  };
}
