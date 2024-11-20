{ pkgs, ... }:
{
  programs.emacs = {
    enable = true;
    package = (pkgs.emacsPackagesFor pkgs.emacs29-pgtk).emacsWithPackages (
      epkgs: with epkgs; [
        crux
        lsp-mode
        magit
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
