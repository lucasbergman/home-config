{ lib, ... }:
{
  resource.linode_instance.pinchy = {
    label = "pinchy";
    type = "g6-nanode-1";
    region = lib.tfRef "var.linode_region";
  };

  resource.linode_instance_disk.pinchy_swap = {
    label = "swap";
    linode_id = lib.tfRef "linode_instance.pinchy.id";
    size = 256; # MB
    filesystem = "swap";
  };

  resource.linode_instance_disk.pinchy_boot = {
    label = "boot";
    linode_id = lib.tfRef "linode_instance.pinchy.id";
    size = lib.tfRef "linode_instance.pinchy.specs.0.disk - linode_instance_disk.pinchy_swap.size";
    image = lib.tfRef "data.linode_image.spot_nixos.id";
  };

  resource.linode_instance_config.pinchy = {
    linode_id = lib.tfRef "linode_instance.pinchy.id";
    label = "pinchy";
    kernel = "linode/grub2";
    root_device = "/dev/sda";
    booted = true;

    device = [
      {
        device_name = "sda";
        disk_id = lib.tfRef "linode_instance_disk.pinchy_boot.id";
      }
      {
        device_name = "sdb";
        disk_id = lib.tfRef "linode_instance_disk.pinchy_swap.id";
      }
    ];
  };

  resource.google_dns_record_set = {
    bergmans_a_pinchy = {
      managed_zone = lib.tfRef "google_dns_managed_zone.bergmans.name";
      name = "pinchy.bergmans.us.";
      type = "A";
      rrdatas = lib.tfRef "[linode_instance.pinchy.ip_address]";
      ttl = 300;
    };
    bergmans_aaaa_pinchy = {
      managed_zone = lib.tfRef "google_dns_managed_zone.bergmans.name";
      name = "pinchy.bergmans.us.";
      type = "AAAA";
      rrdatas = lib.tfRef "[split(\"/\", linode_instance.pinchy.ipv6)[0]]";
      ttl = 300;
    };
  };

  resource.google_service_account.instance_pinchy = {
    account_id = "instance-pinchy";
    display_name = "Pinchy VM instance account";
  };

  resource.google_project_iam_member.pinchy_acme_dns = {
    project = lib.tfRef "var.gcp_project";
    role = lib.tfRef "google_project_iam_custom_role.acme_dns.name";
    member = "serviceAccount:\${google_service_account.instance_pinchy.email}";
  };

  resource.google_project_iam_member.pinchy_log_writer = {
    project = lib.tfRef "var.gcp_project";
    role = "roles/logging.logWriter";
    member = "serviceAccount:\${google_service_account.instance_pinchy.email}";
  };
}
