{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
{
  options.slb.enableDevelopment = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable development tools and packages";
  };

  config = lib.mkIf config.slb.enableDevelopment (
    let
      inherit (config) slb;
    in
    {
      home.packages = [
        pkgs.nixd
        pkgs-unstable.claude-code
        pkgs-unstable.gemini-cli
      ];

      programs.emacs = {
        enable = true;
        package =
          let
            emacsPackage = if slb.isDesktop then pkgs.emacs30-pgtk else pkgs.emacs30-nox;
          in
          (pkgs.emacsPackagesFor emacsPackage).emacsWithPackages (
            epkgs: with epkgs; [
              bazel
              crux
              direnv
              eglot
              fireplace
              lsp-mode
              magit
              mu4e
              nix-mode
              smex
              use-package
            ]
          );
        extraConfig = ''
          (load "${./emacs.el}")
        '';
      };

      programs.vscode = {
        enable = slb.isDesktop;
        profiles.default.extensions = with pkgs.vscode-extensions; [
          bbenoist.nix
          ms-python.debugpy
          ms-python.mypy-type-checker
          ms-python.python
          ms-vscode-remote.remote-ssh
        ];
      };

      services.vscode-server.enable = (!slb.isDesktop) && slb.enableDevelopment;

      services.emacs = {
        enable = true;
        client.enable = true;
        defaultEditor = true;
        socketActivation.enable = true;
      };
    }
  );
}
