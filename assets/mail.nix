{ lib, ... }:
let
  sesForDomain =
    {
      name,
      domain,
      project ? "bergmans-services",
    }:
    {
      resource.aws_ses_domain_identity."${name}" = {
        inherit domain;
      };
      resource.aws_ses_domain_dkim."${name}" = {
        inherit domain;
      };
      resource.google_dns_record_set = {
        "${name}_ses_dkim_0" = {
          inherit project;
          managed_zone = name;
          name = "\${aws_ses_domain_dkim.${name}.dkim_tokens[0]}._domainkey.${domain}.";
          type = "CNAME";
          rrdatas = [ "\${aws_ses_domain_dkim.${name}.dkim_tokens[0]}.dkim.amazonses.com." ];
          ttl = 3600;
        };
        "${name}_ses_dkim_1" = {
          inherit project;
          managed_zone = name;
          name = "\${aws_ses_domain_dkim.${name}.dkim_tokens[1]}._domainkey.${domain}.";
          type = "CNAME";
          rrdatas = [ "\${aws_ses_domain_dkim.${name}.dkim_tokens[1]}.dkim.amazonses.com." ];
          ttl = 3600;
        };
        "${name}_ses_dkim_2" = {
          inherit project;
          managed_zone = name;
          name = "\${aws_ses_domain_dkim.${name}.dkim_tokens[2]}._domainkey.${domain}.";
          type = "CNAME";
          rrdatas = [ "\${aws_ses_domain_dkim.${name}.dkim_tokens[2]}.dkim.amazonses.com." ];
          ttl = 3600;
        };
      };
    };

  dmarcForDomain =
    {
      name,
      domain,
      project ? "bergmans-services",
    }:
    {
      resource.google_dns_record_set."${name}_dmarc" = {
        inherit project;
        managed_zone = name;
        name = "_dmarc.${domain}.";
        type = "TXT";
        rrdatas = [ "\"v=DMARC1; p=none; rua=mailto:postmaster@${domain}\"" ];
        ttl = 3600;
      };
    };
in
builtins.foldl' lib.attrsets.recursiveUpdate { } [
  (sesForDomain {
    name = "bergmans";
    domain = "bergmans.us";
  })
  (dmarcForDomain {
    name = "bergmans";
    domain = "bergmans.us";
  })

  (sesForDomain {
    name = "bergmanhouse";
    domain = "bergman.house";
  })
  (dmarcForDomain {
    name = "bergmanhouse";
    domain = "bergman.house";
  })

  (sesForDomain {
    name = "blurt";
    domain = "blurt.chat";
  })
  (dmarcForDomain {
    name = "blurt";
    domain = "blurt.chat";
  })

  (sesForDomain {
    name = "smartmouse";
    domain = "smartmousetravel.com";
    project = "smartmouse-web";
  })
  (dmarcForDomain {
    name = "smartmouse";
    domain = "smartmousetravel.com";
    project = "smartmouse-web";
  })

  {
    resource.google_secret_manager_secret = {
      # SES password for mail submission
      mail_ses_password = {
        secret_id = "mail-ses-password";
        replication.auto = { };
      };

      # User names and (hashed) passwords for mail server users
      mail_userdb = {
        secret_id = "mail-userdb";
        replication.auto = { };
      };

      # Transport map for Postfix
      mail_transport = {
        secret_id = "mail-transport";
        replication.auto = { };
      };

      # Virtual mailbox mappings for Postfix
      mail_virtual_mailbox = {
        secret_id = "mail-virtual-mailbox";
        replication.auto = { };
      };

      # Virtual alias mappings for Postfix
      mail_virtual_alias = {
        secret_id = "mail-virtual-alias";
        replication.auto = { };
      };

      mail_arc_private_key_202510 = {
        secret_id = "mail-arc-private-key-202510";
        replication.auto = { };
      };
    };

    resource.google_dns_record_set = {
      mail_arc_key_202510 = {
        managed_zone = "bergmans";
        name = "arc202510._domainkey.bergmans.us.";
        type = "TXT";
        rrdatas = [
          "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqxYsMxmVdnEJTJHazK3D3p577cb5QYkx76nCt23jNsiAgyJtDbyuo+CdkhiQziqqlIErZ/jcvn3KhJRK0HpWNsjGCFcsoEVjJ3vkm7ispLZrOIWWiUUsnG9W76cN0zKyPKEiknZeR0as6kdgUbc3E7KhCFhtLM8kG5QX91K67M3JzdkOJ0XJrFIzmhwvFMFJR\" \"L9pLfpZPV5iVRMU+ZhRb6oqgLwx7hMaluHHKlhFjIPHk9gdeYu9AAR+ZvTA3xvkIoWci4AiYj97CTQQaI56JulkeehZMt0uSyz3EATvz+If8WwNeUG8ACfu+/Q+518S+RyZO2ww+cgEVehFOKwq2QIDAQAB\""
        ];
        ttl = 300;
      };
    };

    # Inbound mail delivery for smartmousetravel.com
    resource.google_dns_record_set = {
      smartmouse_a_mail = {
        managed_zone = "smartmouse";
        project = "smartmouse-web";
        name = "mail.smartmousetravel.com.";
        type = "A";
        rrdatas = [ (lib.tfRef "linode_instance.cheddar.ip_address") ];
        ttl = 300;
      };

      smartmouse_mx = {
        managed_zone = "smartmouse";
        project = "smartmouse-web";
        name = "smartmousetravel.com.";
        type = "MX";
        rrdatas = [ "10 smtp.bergmans.us." ];
        ttl = 300;
      };
    };
  }
]
