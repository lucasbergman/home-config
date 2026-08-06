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

      # Handle the mail spool sitting on the IMAP server; real mail gets sent to
      # Fastmail, so this is going to be stuff for postmaster@ etc.
      accounts.email.accounts = {
        ${slb.notmuch.primaryMailAccount} = {
          primary = true;
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
            create = "both";
            expunge = "both";
          };
        };

        # Do a one-way sync from Fastmail to disk, just in case they have data loss
        fastmail = {
          maildir.path = "/home/lucas/mail-backup/fastmail";
          imap = {
            host = "imap.fastmail.com";
            port = 993;
            tls.enable = true;
          };
          userName = "lucasbergman@fastmail.com";
          passwordCommand = "cat ~/.secret/fastmail-app-password";
          mbsync = {
            enable = true;
            create = "maildir";
            expunge = "none";
            extraConfig.channel = {
              Sync = "Pull";
            };
          };
        };
      };

      programs.emacs.extraConfig = ''
        (load "${./mail.el}")
        (setq sendmail-program "${sendmail}")
      '';

      programs.mbsync.enable = true;
      programs.notmuch.enable = true;

      programs.afew = {
        enable = true;
        extraConfig = builtins.readFile ./afew.conf;
      };

      services.mbsync = {
        enable = true;
        frequency = "*:0/10";
        postExec = "${pkgs.notmuch}/bin/notmuch new && ${pkgs.afew}/bin/afew --tag --new";
      };

      # Hack the mbsync service to just sync the spool account, not everything
      systemd.user.services.mbsync.Service.ExecStart =
        lib.mkForce "${pkgs.isync}/bin/mbsync ${slb.notmuch.primaryMailAccount}";

      # Separate mbsync setup that backs up fastmail daily
      systemd.user.services.mbsync-fastmail = {
        Unit.Description = "mbsync fastmail backup service";
        Service = {
          ExecStart = "${pkgs.isync}/bin/mbsync fastmail";
        };
      };
      systemd.user.timers.mbsync-fastmail = {
        Unit.Description = "Daily mbsync fastmail backup timer";
        Timer = {
          OnCalendar = "daily";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    }
  );
}
