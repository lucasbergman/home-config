{ lib, ... }:
{
  resource.linode_instance.cheddar = {
    label = "cheddar";
    type = lib.tfRef "var.linode_type";
    region = lib.tfRef "var.linode_region";
  };

  resource.linode_instance_disk = {
    cheddar_swap = {
      label = "swap";
      linode_id = lib.tfRef "linode_instance.cheddar.id";
      size = 1024; # MB
      filesystem = "swap";
    };

    cheddar_install = {
      label = "installer";
      linode_id = lib.tfRef "linode_instance.cheddar.id";
      size = 1024; # MB
    };
  };

  resource.linode_instance_disk.cheddar_boot = {
    label = "boot";
    linode_id = lib.tfRef "linode_instance.cheddar.id";
    size = lib.tfRef "linode_instance.cheddar.specs.0.disk - linode_instance_disk.cheddar_swap.size - linode_instance_disk.cheddar_install.size";
  };

  resource.linode_volume.cheddar_data = {
    label = "cheddar-data";
    region = lib.tfRef "var.linode_region";
    size = 10; # GB
  };

  resource.linode_instance_config = {
    cheddar_install = {
      linode_id = lib.tfRef "linode_instance.cheddar.id";
      label = "cheddar-install";
      kernel = "linode/direct-disk";
      root_device = "/dev/sdc";

      device = [
        {
          device_name = "sda";
          disk_id = lib.tfRef "linode_instance_disk.cheddar_boot.id";
        }
        {
          device_name = "sdb";
          disk_id = lib.tfRef "linode_instance_disk.cheddar_swap.id";
        }
        {
          device_name = "sdc";
          disk_id = lib.tfRef "linode_instance_disk.cheddar_install.id";
        }
      ];
    };

    cheddar = {
      linode_id = lib.tfRef "linode_instance.cheddar.id";
      label = "cheddar";
      kernel = "linode/grub2"; # use the distro kernel, not Linode's
      root_device = "/dev/sda";

      device = [
        {
          device_name = "sda";
          disk_id = lib.tfRef "linode_instance_disk.cheddar_boot.id";
        }
        {
          device_name = "sdb";
          disk_id = lib.tfRef "linode_instance_disk.cheddar_swap.id";
        }
        {
          device_name = "sdc";
          volume_id = lib.tfRef "linode_volume.cheddar_data.id";
        }
      ];
    };
  };

  resource.google_dns_record_set =
    let
      zone = lib.tfRef "google_dns_managed_zone.bergmans.name";
      mkip4 = name: {
        managed_zone = zone;
        name = "${name}.bergmans.us.";
        type = "A";
        rrdatas = lib.tfRef "[linode_instance.cheddar.ip_address]";
        ttl = 300;
      };
      mkip6 = name: {
        managed_zone = zone;
        name = "${name}.bergmans.us.";
        type = "AAAA";
        rrdatas = lib.tfRef "[split(\"/\", linode_instance.cheddar.ipv6)[0]]";
        ttl = 300;
      };
    in
    {
      bergmans_a_cheddar = mkip4 "cheddar";
      bergmans_aaaa_cheddar = mkip6 "cheddar";
      bergmans_a_dash = mkip4 "dash";
      bergmans_aaaa_dash = mkip6 "dash";
      bergmans_a_mumble = mkip4 "mumble";
      bergmans_aaaa_mumble = mkip6 "mumble";
      bergmans_a_pop = mkip4 "pop";
      bergmans_aaaa_pop = mkip6 "pop";
      bergmans_a_smtp = mkip4 "smtp";
      bergmans_aaaa_smtp = mkip6 "smtp";

      # TODO: Delete this when POP3 clients are moved to pop.bergmans.us
      bergmans_a_greywind = mkip4 "greywind";
    };

  # Create an instance-level GCP service account and make it a member of
  # IAM roles to enable DNS writes for ACME-generated certificates, log
  # shipping, and writing backups.

  resource.google_service_account.instance_cheddar = {
    account_id = "instance-cheddar";
    display_name = "Cheddar VM instance account";
  };

  resource.google_project_iam_member.cheddar_acme_dns = {
    project = lib.tfRef "var.gcp_project";
    role = lib.tfRef "google_project_iam_custom_role.acme_dns.name";
    member = "serviceAccount:\${google_service_account.instance_cheddar.email}";
  };

  resource.google_project_iam_member.cheddar_log_writer = {
    project = lib.tfRef "var.gcp_project";
    role = "roles/logging.logWriter";
    member = "serviceAccount:\${google_service_account.instance_cheddar.email}";
  };

  resource.google_storage_bucket_iam_member.cheddar_backup = {
    bucket = lib.tfRef "google_storage_bucket.backup.name";
    role = "roles/storage.objectAdmin";
    member = "serviceAccount:\${google_service_account.instance_cheddar.email}";
  };

  resource.google_service_account_key.instance_cheddar = {
    service_account_id = lib.tfRef "google_service_account.instance_cheddar.id";
  };

  resource.local_sensitive_file.instance_cheddar = {
    file_permission = "0600";
    content_base64 = lib.tfRef "google_service_account_key.instance_cheddar.private_key";
    filename = "\${path.module}/cheddar-instance-private-key.json";
  };

  resource.google_secret_manager_secret =
    let
      mkSecret = name: {
        secret_id = name;
        replication = {
          auto = { };
        };
      };
    in
    {
      restic_password_cheddar = mkSecret "restic-password-cheddar";
      mumble_password = mkSecret "mumble-password";
      pagerduty_key = mkSecret "pagerduty-key";
    };

  resource.google_secret_manager_secret_iam_member =
    let
      mkMember = secret: {
        secret_id = lib.tfRef "google_secret_manager_secret.${secret}.secret_id";
        role = "roles/secretmanager.secretAccessor";
        member = "serviceAccount:\${google_service_account.instance_cheddar.email}";
      };
    in
    {
      cheddar_restic_password_cheddar = mkMember "restic_password_cheddar";
      cheddar_mumble_password = mkMember "mumble_password";
      cheddar_pagerduty_key = mkMember "pagerduty_key";
      cheddar_mail_ses_password = mkMember "mail_ses_password";
      cheddar_mail_userdb = mkMember "mail_userdb";
      cheddar_mail_arc_private_key = mkMember "mail_arc_private_key_202510";
    };
}
