{
  lib,
  pkgs,
  vscode-server,
  ...
}:
{
  imports = [
    vscode-server.homeModules.default
    ./desktop
    ./development
  ];

  options.slb = {
    isDesktop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host is a GUI desktop environment";
    };
  };

  config = {
    home = {
      username = "lucas";
      homeDirectory = "/home/lucas";
      stateVersion = "23.05";
    };

    home.packages = [
      pkgs.bitwarden-cli
      pkgs.inetutils
      pkgs.jq
      pkgs.netcat-gnu
      pkgs.nodejs_22
      pkgs.vim
    ];

    nixpkgs.config.allowUnfree = true;

    programs.home-manager.enable = true;

    programs.bash = {
      enable = true;
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

    programs.tmux = {
      enable = true;
      prefix = "C-o";
    };

    programs.git = {
      enable = true;
      userName = "Lucas Bergman";
      userEmail = "lucas@bergmans.us";
      extraConfig = {
        init.defaultBranch = "main";
      };

      aliases = {
        co = "checkout";
        graph = "log --graph --oneline --decorate";
        st = "status";
        staged = "diff --staged";
      };
    };

    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          email = "lucas@bergmans.us";
          name = "Lucas Bergman";
        };
      };
    };
  };
}
