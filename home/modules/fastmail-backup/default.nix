{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.slb.fastmailBackup = {
    enable = lib.mkEnableOption "Daily Fastmail backup via mbsync";
  };

  config = lib.mkIf config.slb.fastmailBackup.enable {
    accounts.email.maildirBasePath = "mail-backup";

    # Do a one-way sync from Fastmail to disk, just in case they have data loss
    accounts.email.accounts.fastmail = {
      maildir.path = "fastmail";
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

    programs.mbsync.enable = true;

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
  };
}
