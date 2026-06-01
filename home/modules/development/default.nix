{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  mypkgs,
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
        pkgs.gh
        pkgs.nixd
        pkgs.w3m
        mypkgs.google-antigravity-cli
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
              notmuch
              smex
              use-package
              w3m
            ]
          );
        extraConfig = ''
          (load "${./emacs.el}")
        '';
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
