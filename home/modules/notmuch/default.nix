{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.slb.notmuch = {
    enable = lib.mkEnableOption {
      description = "Whether to enable development tools and packages";
    };

    primaryMailAccount = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf config.slb.notmuch.enable (
    let
      inherit (config) slb;
      sendmail = pkgs.writeShellScript "ssh-sendmail" ''
        exec ssh -T cheddar.priv.bergman.house sendmail "$@"
      '';
    in
    {
      accounts.email.maildirBasePath = "/home/lucas/mail";
      accounts.email.accounts.${slb.notmuch.primaryMailAccount} = {
        maildir.path = "spool";
        imap.host = "pop.bergmans.us";
        smtp = {
          host = "smtp.bergmans.us";
          port = 587;
          tls.useStartTls = true;
        };
        userName = "lucas@bergmans.us";
        passwordCommand = "cat ~/.secret/mail";
        mbsync = {
          enable = true;
          create = "maildir";
          expunge = "imap";
        };
      };

      programs.emacs.extraConfig = ''
        (load "${./mail.el}")
        (setq sendmail-program "${sendmail}")
      '';

      programs.afew.enable = true;
      programs.mbsync.enable = true;
      programs.notmuch.enable = true;

      services.mbsync = {
        enable = true;
        frequency = "*:0/10";
        postExec = "${pkgs.notmuch}/bin/notmuch new && ${pkgs.afew}/bin/afew --tag --new";
      };
    }
  );
}
