{ pkgs, ... }:
{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-gtk;

    extraPackages =
      epkgs: with epkgs; [
        lsp-mode
        magit
        nix-mode
        use-package
      ];
  };

  services.emacs = {
    enable = true;
    client.enable = true;
    defaultEditor = true;
    socketActivation.enable = true;
  };
}
