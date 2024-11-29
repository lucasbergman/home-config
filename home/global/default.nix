{
  pkgs,
  pkgs-unstable,
  ...
}:
{
  imports = [ ./emacs.nix ];

  home = {
    username = "lucas";
    homeDirectory = "/home/lucas";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "23.05";
  };

  home.packages = [
    pkgs.inetutils
    pkgs.jq
    pkgs.netcat-gnu
    pkgs.vim

    pkgs-unstable.bitwarden-cli
  ];

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true; # LOL
    historyFileSize = 200000;
    historyControl = [ "erasedups" ];
  };

  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        "charset" = "utf-8";
        "end_of_line" = "lf";
        "indent_size" = 2;
        "indent_style" = "space";
        "insert_final_newline" = true;
        "trim_trailing_whitespace" = true;
      };
    };
  };

  programs.direnv.enable = true;

  programs.git = {
    enable = true;
    userName = "Lucas Bergman";
    userEmail = "lucas@bergmans.us";

    aliases = {
      co = "checkout";
      graph = "log --graph --oneline --decorate";
      st = "status";
      staged = "diff --staged";
    };
  };
}
