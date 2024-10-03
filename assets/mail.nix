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
in
builtins.foldl' lib.attrsets.recursiveUpdate { } [
  (sesForDomain {
    name = "bergmans";
    domain = "bergmans.us";
  })

  (sesForDomain {
    name = "bergmanhouse";
    domain = "bergman.house";
  })

  (sesForDomain {
    name = "blurt";
    domain = "blurt.chat";
  })

  (sesForDomain {
    name = "smartmouse";
    domain = "smartmousetravel.com";
    project = "smartmouse-web";
  })

  {
    resource.google_secret_manager_secret = {
      # SES password for mail submission
      mail_ses_password = {
        secret_id = "mail-ses-password";
        replication = {
          auto = { };
        };
      };

      # User names and (hashed) passwords for mail server users
      mail_userdb = {
        secret_id = "mail-userdb";
        replication = {
          auto = { };
        };
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
        rrdatas = [ "10 mail.smartmousetravel.com." ];
        ttl = 300;
      };
    };
  }
]
