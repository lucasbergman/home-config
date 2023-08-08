{
  config,
  lib,
  mypkgs,
  ...
}: let
  postfixTLSHost = "smtp.bergmans.us";
  postfixDomain = "bergmans.us";
  dovecotTLSHost = "pop.bergmans.us";
  mailDirectory = "/data/mail";
  saslPasswordFile = "/run/sasl_passwd";
  dovecotUserFile = "/run/dovecot_users";
  dovecotUserFileSecret = "projects/bergmans-services/secrets/mail-userdb/versions/1";
  vmail_uid = 2000;
  vmail_gid = 2000;
in {
  security.acme.certs.${postfixTLSHost} = {
    reloadServices = ["postfix.service"];
  };

  users = {
    groups.vmail.gid = vmail_gid;
    users.vmail = {
      uid = vmail_uid;
      group = "vmail";
      createHome = false;
      home = "${mailDirectory}/users";
      isNormalUser = true;
    };
  };

  system.activationScripts."mail-storage" = {
    deps = ["users" "groups"];
    text = let
      dir = lib.escapeShellArg "${mailDirectory}/users";
    in ''
      if [[ ! -e ${dir} ]]; then
        install -d -m 750 -o vmail -g vmail ${dir}
      else
        chmod 750 ${dir}
        chown --recursive vmail:vmail ${dir}
      fi
    '';
  };

  systemd.services."postfix-ses-password" = {
    description = "decrypt SES SMTP password";
    wantedBy = ["multi-user.target"];
    before = ["postfix.service" "postfix-setup.service"];
    after = ["instance-key.service"];
    serviceConfig.Type = "oneshot";
    environment = {
      GOOGLE_APPLICATION_CREDENTIALS = "/run/gcp-instance-creds.json";
    };

    script = ''
      if [[ ! -f ${saslPasswordFile} ]]; then
        install -m 0640 -g postfix /dev/null ${saslPasswordFile}
        ${mypkgs.gcp-secret-subst}/bin/gcp-secret-subst \
          ${./../conf/postfix/sasl_passwd}              \
          > ${saslPasswordFile}
      fi
    '';
  };

  services.postfix = {
    enable = true;
    domain = postfixDomain;
    hostname = postfixTLSHost;
    origin = "$myhostname";
    sslCert = "/var/lib/acme/${postfixTLSHost}/cert.pem";
    sslKey = "/var/lib/acme/${postfixTLSHost}/key.pem";

    postmasterAlias = "root";
    rootAlias = "lucas@bergmans.us";

    # Allow users to have infinite '+'-separated addresses
    recipientDelimiter = "+";

    # Pretend Amazon SES is the next-hop MX for all non-local mail delivery
    # (overrides the recipient domain)
    relayHost = "email-smtp.us-east-2.amazonaws.com";
    relayPort = 587;

    mapFiles.virtual_alias = ./../conf/postfix/virtual_alias;
    mapFiles.virtual_mailbox = ./../conf/postfix/virtual_mailbox;
    mapFiles.sasl_passwd = saslPasswordFile;

    # Set up some deeper mumbo-jumbo not supported by the NixOS module
    config = {
      compatibility_level = "3.7";

      # 64 MiB (default is about 10)
      message_size_limit = "67108864";
      virtual_mailbox_limit = "$message_size_limit";

      smtpd_banner = "$myhostname ESMTP";
      smtpd_helo_required = true;
      smtpd_recipient_restrictions = [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject_rbl_client zen.spamhaus.org=127.0.0.[2..11]"
        "reject_rhsbl_sender dbl.spamhaus.org=127.0.1.[2..99]"
        "reject_rhsbl_helo dbl.spamhaus.org=127.0.1.[2..99]"
        "reject_rhsbl_reverse_client dbl.spamhaus.org=127.0.1.[2..99]"
        "warn_if_reject reject_rbl_client zen.spamhaus.org=127.255.255.[1..255]"
        "reject_non_fqdn_recipient"
        "reject_unknown_recipient_domain"
        "reject_unauth_destination"
      ];
      smtpd_relay_restrictions = [
        "permit_mynetworks"
        "permit_sasl_authenticated"
        "reject_unauth_destination"
      ];
      smtpd_sender_restrictions = "reject_unknown_sender_domain";
      smtpd_tls_auth_only = true; # only allow SMTP auth over TLS connection

      # Enable authentication for incoming SMTP; non-local clients can only
      # use us as a relay or skip spam checks if they're SASL-authenticated.
      # (See permit_sasl_authenticated above.)
      smtpd_sasl_auth_enable = true;
      smtpd_sasl_local_domain = "$mydomain";
      smtpd_sasl_path = "private/auth";
      smtpd_sasl_type = "dovecot";

      # Postfix should never act as an SMTP client except to the Amazon relay
      # host, so it's safe to set a high security bar
      smtp_use_tls = true;
      smtp_tls_security_level = "secure";
      smtp_tls_mandatory_ciphers = "high";
      smtp_tls_mandatory_protocols = ">=TLSv1.2";

      # Enable authentication for outgoing SMTP
      smtp_sasl_auth_enable = true;
      smtp_sasl_password_maps = "hash:/var/lib/postfix/conf/sasl_passwd";
      smtp_sasl_security_options = ["noanonymous"];

      # Virtual mailbox domains are for when Postfix does "final delivery for
      # hosted domains where each recipient address can have its own mailbox."
      virtual_mailbox_domains = "bergmans.us";
      virtual_mailbox_maps = "hash:/var/lib/postfix/conf/virtual_mailbox";
      virtual_mailbox_base = "${mailDirectory}/users";
      virtual_gid_maps = "static:${builtins.toString vmail_gid}";
      virtual_uid_maps = "static:${builtins.toString vmail_uid}";

      # Virtual alias domains are for mail that gets delivered to "hosted
      # domains where each recipient address is aliased to an address in a
      # different domain." Mail for the domains below gets aliased to some
      # address in bergmans.us.
      virtual_alias_domains = [
        "bergman.house"
        "blurt.chat"
        "boozyprofessor.com"
        "smartgirltravel.com"
        "smartmousetravel.com"
      ];
      virtual_alias_maps = "hash:/var/lib/postfix/conf/virtual_alias";
    };
  };

  security.acme.certs.${dovecotTLSHost} = {
    reloadServices = ["dovecot2.service"];
  };

  systemd.services."dovecot-userdb" = {
    description = "download the Dovecot user DB file";
    wantedBy = ["multi-user.target"];
    before = ["dovecot2.service"];
    after = ["instance-key.service"];
    serviceConfig.Type = "oneshot";
    environment = {
      GOOGLE_APPLICATION_CREDENTIALS = "/run/gcp-instance-creds.json";
    };

    script = ''
      if [[ ! -f ${dovecotUserFile} ]]; then
        install -m 0640 -g dovecot2 /dev/null ${dovecotUserFile}
        ${mypkgs.cat-gcp-secret}/bin/cat-gcp-secret  \
          ${dovecotUserFileSecret} > ${dovecotUserFile}
      fi
    '';
  };

  services.dovecot2 = {
    enable = true;
    enablePop3 = true;
    enableImap = true;
    enableLmtp = false;
    enablePAM = false;

    sslServerCert = "/var/lib/acme/${dovecotTLSHost}/cert.pem";
    sslServerKey = "/var/lib/acme/${dovecotTLSHost}/key.pem";
    createMailUser = false;
    mailUser = "vmail";
    mailGroup = "vmail";

    extraConfig = ''
      service auth {
        unix_listener ${config.services.postfix.config.queue_directory}/private/auth {
          mode = 0666
          user = dovecot2
          group = dovecot2
        }
      }

      passdb {
        driver = passwd-file
        args = scheme=CRYPT username_format=%u /run/dovecot_users
        default_fields = userdb_mail=maildir
      }

      userdb {
        driver = passwd-file
        args = username_format=%u /run/dovecot_users
      }

      namespace inbox {
        inbox = yes
      }

      ssl_min_protocol = TLSv1.2
    '';
  };
}
