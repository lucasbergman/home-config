{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;
    shfmt = {
      enable = true;
      indent_size = 4;
    };
  };
}
