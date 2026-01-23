{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    black.enable = true;
    isort.enable = true;
    nixfmt.enable = true;
    prettier = {
      enable = true;
      settings = {
        printWidth = 88;
        proseWrap = "always";
      };
    };
    shfmt = {
      enable = true;
      indent_size = 4;
    };
  };

  settings.formatter = {
    black.options = [ "--line-length=88" ];
  };
}
