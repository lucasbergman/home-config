{
  config,
  lib,
  pkgs,
  ...
}:
let
  postfixDomain = "bergmans.us";
  postfixTLSHost = "smtp.${postfixDomain}";
  dovecotTLSHost = "pop.${postfixDomain}";
  dovecotLegacyTLSHost = "greywind.${postfixDomain}";
  mailDirectory = "/data/mail";
  saslPasswordFile = "/run/sasl_passwd";
  dovecotUserFile = "/run/dovecot_users";
  dovecotUserFileSecret = "projects/bergmans-services/secrets/mail-userdb/versions/3";
  transportFile = "/run/postfix_transport";
  transportSecret = "projects/bergmans-services/secrets/mail-transport/versions/1";
  virtualMailboxFile = "/run/virtual_mailbox";
  virtualMailboxSecret = "projects/bergmans-services/secrets/mail-virtual-mailbox/versions/3";
  virtualAliasFile = "/run/virtual_alias";
  virtualAliasSecret = "projects/bergmans-services/secrets/mail-virtual-alias/versions/3";
  vmail_uid = 2000;
  vmail_gid = 2000;
  openarcUID = 2002;
  openarcKeyFile = "/run/openarc.key";
  openarcKeySecret = "projects/bergmans-services/secrets/mail-arc-private-key-202510/versions/1";
  opendkimSelector = "dkim202601";
  opendkimKeyFile = "/var/lib/opendkim/keys/${opendkimSelector}.private";
  opendkimKeySecret = "projects/bergmans-services/secrets/mail-dkim-private-key-202601/versions/1";

  # Virtual mailbox domains are for when Postfix does "final delivery for
  # hosted domains where each recipient address can have its own mailbox."
  virtualMailboxDomains = [
    "bergmans.us"
    "mcfarlandsllamafarm.com"
  ];
  # Virtual alias domains are for mail that gets delivered to "hosted
  # domains where each recipient address is aliased to an address in a
  # different domain." Mail for the domains below gets aliased to some
  # address in bergmans.us.
  virtualAliasDomains = [
    "bergman.house"
    "blurt.chat"
    "boozyprofessor.com"
    "smartgirltravel.com"
    "smartmousetravel.com"
  ];
  allMailDomains = virtualMailboxDomains ++ virtualAliasDomains;
in
{
  security.acme.certs.${postfixTLSHost} = {
    keyType = "rsa4096";
    reloadServices = [ "postfix.service" ];
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
    deps = [
      "users"
      "groups"
    ];
    text =
      let
        dir = lib.escapeShellArg "${mailDirectory}/users";
      in
      ''
        if [[ ! -e ${dir} ]]; then
          install -d -m 750 -o vmail -g vmail ${dir}
        else
          chmod 750 ${dir}
          chown --recursive vmail:vmail ${dir}
        fi
      '';
  };

  slb.security.secrets."postfix-ses-password" = {
    before = [
      "postfix.service"
      "postfix-setup.service"
    ];
    outPath = saslPasswordFile;
    group = "postfix";
    template = pkgs.writeText "sasl_passwd" ''
      [email-smtp.us-east-2.amazonaws.com]:587 {{gcpSecret "projects/bergmans-services/secrets/mail-ses-password/versions/1"}}
    '';
  };

  slb.security.secrets."postfix-transport" = {
    before = [
      "postfix.service"
      "postfix-setup.service"
    ];
    outPath = transportFile;
    group = "postfix";
    secretPath = transportSecret;
  };

  slb.security.secrets."postfix-virtual-mailbox" = {
    before = [
      "postfix.service"
      "postfix-setup.service"
    ];
    outPath = virtualMailboxFile;
    group = "postfix";
    secretPath = virtualMailboxSecret;
  };

  slb.security.secrets."postfix-virtual-alias" = {
    before = [
      "postfix.service"
      "postfix-setup.service"
    ];
    outPath = virtualAliasFile;
    group = "postfix";
    secretPath = virtualAliasSecret;
  };

  services.postfix = {
    enable = true;

    postmasterAlias = "root";
    rootAlias = "lucas@bergmans.us";

    enableSubmission = true;
    submissionOptions = {
      smtpd_tls_security_level = "encrypt";
      smtpd_client_restrictions = "permit_mynetworks,permit_sasl_authenticated,reject";
      # Submission uses OpenDKIM for signing (no ARC verify/seal needed).
      smtpd_milters = "inet:127.0.0.1:8892";
    };

    mapFiles.transport = transportFile;
    mapFiles.virtual_alias = virtualAliasFile;
    mapFiles.virtual_mailbox = virtualMailboxFile;
    mapFiles.sasl_passwd = saslPasswordFile;

    settings.main = {
      compatibility_level = "3.7";

      myhostname = postfixTLSHost;
      mydomain = postfixDomain;
      myorigin = "$myhostname";

      mynetworks = [
        "127.0.0.0/8"
        "10.6.0.0/24" # Include WireGuard mesh in trusted networks
      ];

      smtpd_tls_chain_files = [
        "/var/lib/acme/${postfixTLSHost}/key.pem"
        "/var/lib/acme/${postfixTLSHost}/fullchain.pem"
      ];

      # Allow users to have infinite '+'-separated addresses
      recipient_delimiter = "+";

      # Pretend Amazon SES is the next-hop MX for all non-local mail delivery
      # (overrides the recipient domain)
      relayhost = [ "[email-smtp.us-east-2.amazonaws.com]:587" ];

      # 64 MiB (default is about 10)
      message_size_limit = 67108864;
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

      # Use opportunistic TLS for outbound SMTP. Even Gmail servers flunk name
      # verification with smtp_tls_security_level set to "secure".
      smtp_tls_security_level = "may";
      smtp_tls_mandatory_ciphers = "high";
      smtp_tls_mandatory_protocols = ">=TLSv1.2";

      # Enable authentication for outgoing SMTP
      smtp_sasl_auth_enable = true;
      smtp_sasl_password_maps = "hash:/var/lib/postfix/conf/sasl_passwd";
      smtp_sasl_security_options = [ "noanonymous" ];

      virtual_mailbox_domains = virtualMailboxDomains;

      transport_maps = "hash:/var/lib/postfix/conf/transport";
      virtual_mailbox_maps = "hash:/var/lib/postfix/conf/virtual_mailbox";
      virtual_mailbox_base = "${mailDirectory}/users";
      virtual_gid_maps = "static:${builtins.toString vmail_gid}";
      virtual_uid_maps = "static:${builtins.toString vmail_uid}";

      virtual_alias_domains = virtualAliasDomains;
      virtual_alias_maps = "hash:/var/lib/postfix/conf/virtual_alias";

      # OpenARC Milter (verify incoming + seal forwarded mail on port 25)
      smtpd_milters = "inet:127.0.0.1:8891";
      milter_default_action = "tempfail";
      # Local mail (cron, etc.) uses OpenDKIM for signing.
      non_smtpd_milters = "inet:127.0.0.1:8892";
    };
  };

  security.acme.certs.${dovecotTLSHost} = {
    reloadServices = [ "dovecot2.service" ];
  };

  security.acme.certs.${dovecotLegacyTLSHost} = {
    reloadServices = [ "dovecot2.service" ];
  };

  slb.security.secrets.dovecot-userdb = {
    before = [ "dovecot2.service" ];
    outPath = dovecotUserFile;
    group = "dovecot2";
    secretPath = dovecotUserFileSecret;
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
        unix_listener ${config.services.postfix.settings.main.queue_directory}/private/auth {
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

      local_name ${dovecotLegacyTLSHost} {
        ssl_cert = </var/lib/acme/${dovecotLegacyTLSHost}/cert.pem
        ssl_key = </var/lib/acme/${dovecotLegacyTLSHost}/key.pem
      }

      ssl_min_protocol = TLSv1.2
    '';
  };

  slb.security.secrets.openarc-private-key = {
    after = [ "openarc-setup.service" ];
    before = [ "openarc.service" ];
    outPath = openarcKeyFile;
    owner = "openarc";
    secretPath = openarcKeySecret;
  };

  services.openarc = {
    enable = true;
    uid = openarcUID;
    domain = "bergmans.us";
    selector = "arc202510";
    keyFile = openarcKeyFile;
    socket = "inet:8891@localhost";
    mode = "sv";
    internalHosts = [
      "127.0.0.1"
      "::1"
      "10.6.0.0/24"
    ];
    milterUsers = [ "postfix" ];
  };

  slb.security.secrets.opendkim-private-key = {
    before = [ "opendkim.service" ];
    outPath = opendkimKeyFile;
    owner = "opendkim";
    secretPath = opendkimKeySecret;
  };

  services.opendkim = {
    enable = true;
    selector = opendkimSelector;
    domains = "csl:${lib.concatStringsSep "," allMailDomains}";
    socket = "inet:8892@localhost";
    settings = {
      Syslog = "true";
    };
  };
}
