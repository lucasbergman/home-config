{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.slb.enableDevelopment = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable development tools and packages";
  };

  config = lib.mkIf config.slb.enableDevelopment {
    programs.emacs = {
      enable = true;
      package =
        let
          emacsPackage = if config.slb.isDesktop then pkgs.emacs30-pgtk else pkgs.emacs30-nox;
        in
        (pkgs.emacsPackagesFor emacsPackage).emacsWithPackages (
          epkgs: with epkgs; [
            bazel
            crux
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

    services.emacs = {
      enable = true;
      client.enable = true;
      defaultEditor = true;
      socketActivation.enable = true;
    };
  };
}
