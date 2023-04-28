resource "linode_instance" "cheddar" {
  label  = "cheddar"
  type   = var.linode_type
  region = var.linode_region
}

resource "linode_instance_disk" "cheddar_swap" {
  label      = "swap"
  linode_id  = linode_instance.cheddar.id
  size       = 1024 # MB
  filesystem = "swap"
}

resource "linode_instance_disk" "cheddar_install" {
  label     = "installer"
  linode_id = linode_instance.cheddar.id
  size      = 1024 # MB
}

resource "linode_instance_disk" "cheddar_boot" {
  label     = "boot"
  linode_id = linode_instance.cheddar.id
  size      = linode_instance.cheddar.specs.0.disk - linode_instance_disk.cheddar_swap.size - linode_instance_disk.cheddar_install.size
}

resource "linode_volume" "cheddar_data" {
  label  = "cheddar-data"
  region = var.linode_region
  size   = 10 # GB
}

resource "linode_instance_config" "cheddar_install" {
  linode_id = linode_instance.cheddar.id
  label     = "cheddar-install"
  kernel    = "linode/direct-disk"

  root_device = "/dev/sdc"
  devices {
    sda {
      disk_id = linode_instance_disk.cheddar_boot.id
    }
    sdb {
      disk_id = linode_instance_disk.cheddar_swap.id
    }
    sdc {
      disk_id = linode_instance_disk.cheddar_install.id
    }
  }
}

resource "linode_instance_config" "cheddar" {
  linode_id = linode_instance.cheddar.id
  label     = "cheddar"
  kernel    = "linode/grub2" # use the distro kernel, not Linode's

  root_device = "/dev/sda"
  devices {
    sda {
      disk_id = linode_instance_disk.cheddar_boot.id
    }
    sdb {
      disk_id = linode_instance_disk.cheddar_swap.id
    }
    sdc {
      volume_id = linode_volume.cheddar_data.id
    }
  }
}

resource "google_dns_record_set" "bergmans_a_cheddar" {
  managed_zone = "bergmans"
  name         = "cheddar.bergmans.us."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_aaaa_cheddar" {
  managed_zone = "bergmans"
  name         = "cheddar.bergmans.us."
  type         = "AAAA"
  rrdatas      = [split("/", linode_instance.cheddar.ipv6)[0]]
  ttl          = 300
}
