{ pkgs, ... }:
{
  programs.emacs = {
    enable = true;
    package = (pkgs.emacsPackagesFor pkgs.emacs30-pgtk).emacsWithPackages (
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
}
