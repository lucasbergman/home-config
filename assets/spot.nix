{ lib, ... }:
{
  data.linode_image.spot_nixos = {
    id = "private/36872420";
  };

  resource.linode_instance.spot = {
    label = "spot";
    type = "g6-nanode-1";
    region = lib.tfRef "var.linode_region";
  };

  resource.linode_instance_disk.spot_swap = {
    label = "swap";
    linode_id = lib.tfRef "linode_instance.spot.id";
    size = 256; # MB
    filesystem = "swap";
  };

  resource.linode_instance_disk.spot_boot = {
    label = "boot";
    linode_id = lib.tfRef "linode_instance.spot.id";
    size = lib.tfRef "linode_instance.spot.specs.0.disk - linode_instance_disk.spot_swap.size";
    image = lib.tfRef "data.linode_image.spot_nixos.id";
  };

  resource.linode_instance_config.spot = {
    linode_id = lib.tfRef "linode_instance.spot.id";
    label = "spot";
    kernel = "linode/grub2";
    root_device = "/dev/sda";
    booted = true;

    device = [
      {
        device_name = "sda";
        disk_id = lib.tfRef "linode_instance_disk.spot_boot.id";
      }
      {
        device_name = "sdb";
        disk_id = lib.tfRef "linode_instance_disk.spot_swap.id";
      }
    ];
  };

  resource.google_dns_record_set = {
    bergmans_a_spot = {
      managed_zone = lib.tfRef "google_dns_managed_zone.bergmans.name";
      name = "spot.bergmans.us.";
      type = "A";
      rrdatas = lib.tfRef "[linode_instance.spot.ip_address]";
      ttl = 300;
    };
    bergmans_aaaa_spot = {
      managed_zone = lib.tfRef "google_dns_managed_zone.bergmans.name";
      name = "spot.bergmans.us.";
      type = "AAAA";
      rrdatas = lib.tfRef "[split(\"/\", linode_instance.spot.ipv6)[0]]";
      ttl = 300;
    };
  };

  resource.google_service_account.instance_spot = {
    account_id = "instance-spot";
    display_name = "Spot VM instance account";
  };

  resource.google_project_iam_member.spot_acme_dns = {
    project = lib.tfRef "var.gcp_project";
    role = lib.tfRef "google_project_iam_custom_role.acme_dns.name";
    member = "serviceAccount:\${google_service_account.instance_spot.email}";
  };

  resource.google_project_iam_member.spot_log_writer = {
    project = lib.tfRef "var.gcp_project";
    role = "roles/logging.logWriter";
    member = "serviceAccount:\${google_service_account.instance_spot.email}";
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
      nebula_host_key_spot = mkSecret "nebula-host-key-spot";
    };

  resource.google_secret_manager_secret_iam_member =
    let
      mkMember = secret: {
        secret_id = lib.tfRef "google_secret_manager_secret.${secret}.secret_id";
        role = "roles/secretmanager.secretAccessor";
        member = "serviceAccount:\${google_service_account.instance_spot.email}";
      };
    in
    {
      spot_nebula_host_key_spot = mkMember "nebula_host_key_spot";
    };
}
