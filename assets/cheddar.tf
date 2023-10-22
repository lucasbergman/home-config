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
  device {
    device_name = "sda"
    disk_id     = linode_instance_disk.cheddar_boot.id
  }
  device {
    device_name = "sdb"
    disk_id     = linode_instance_disk.cheddar_swap.id
  }
  device {
    device_name = "sdc"
    disk_id     = linode_instance_disk.cheddar_install.id
  }
}

resource "linode_instance_config" "cheddar" {
  linode_id = linode_instance.cheddar.id
  label     = "cheddar"
  kernel    = "linode/grub2" # use the distro kernel, not Linode's

  root_device = "/dev/sda"
  device {
    device_name = "sda"
    disk_id     = linode_instance_disk.cheddar_boot.id
  }
  device {
    device_name = "sdb"
    disk_id     = linode_instance_disk.cheddar_swap.id
  }
  device {
    device_name = "sdc"
    volume_id   = linode_volume.cheddar_data.id
  }
}

resource "google_dns_record_set" "bergmans_a_cheddar" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "cheddar.bergmans.us."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_aaaa_cheddar" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "cheddar.bergmans.us."
  type         = "AAAA"
  rrdatas      = [split("/", linode_instance.cheddar.ipv6)[0]]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_a_dash" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "dash.bergmans.us."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_aaaa_dash" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "dash.bergmans.us."
  type         = "AAAA"
  rrdatas      = [split("/", linode_instance.cheddar.ipv6)[0]]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_a_mumble" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "mumble.bergmans.us."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_aaaa_mumble" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "mumble.bergmans.us."
  type         = "AAAA"
  rrdatas      = [split("/", linode_instance.cheddar.ipv6)[0]]
  ttl          = 300
}

resource "google_dns_record_set" "bergmanhouse_a_matrix" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = "matrix.bergman.house."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 300
}

resource "google_dns_record_set" "bergmanhouse_aaaa_matrix" {
  managed_zone = google_dns_managed_zone.bergmanhouse.name
  name         = "matrix.bergman.house."
  type         = "AAAA"
  rrdatas      = [split("/", linode_instance.cheddar.ipv6)[0]]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_a_smtp" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "smtp.bergmans.us."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_aaaa_smtp" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "smtp.bergmans.us."
  type         = "AAAA"
  rrdatas      = [split("/", linode_instance.cheddar.ipv6)[0]]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_a_pop" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "pop.bergmans.us."
  type         = "A"
  rrdatas      = [linode_instance.cheddar.ip_address]
  ttl          = 300
}

resource "google_dns_record_set" "bergmans_aaaa_pop" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "pop.bergmans.us."
  type         = "AAAA"
  rrdatas      = [split("/", linode_instance.cheddar.ipv6)[0]]
  ttl          = 300
}

# Create an instance-level GCP service account and make it a member of
# IAM roles to enable DNS writes for ACME-generated certificates, log
# shipping, and writing backups.

resource "google_service_account" "instance_cheddar" {
  account_id   = "instance-cheddar"
  display_name = "Cheddar VM instance account"
}

resource "google_project_iam_member" "cheddar_acme_dns" {
  project = var.gcp_project
  role    = google_project_iam_custom_role.acme_dns.name
  member  = "serviceAccount:${google_service_account.instance_cheddar.email}"
}

resource "google_project_iam_member" "cheddar_log_writer" {
  project = var.gcp_project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.instance_cheddar.email}"
}

resource "google_storage_bucket_iam_member" "cheddar_backup" {
  bucket = google_storage_bucket.backup.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.instance_cheddar.email}"
}

resource "google_service_account_key" "instance_cheddar" {
  service_account_id = google_service_account.instance_cheddar.id
}

resource "local_sensitive_file" "instance_cheddar" {
  file_permission = "0600"
  content_base64  = google_service_account_key.instance_cheddar.private_key
  filename        = "${path.module}/cheddar-instance-private-key.json"
}

resource "google_secret_manager_secret" "restic_password_cheddar" {
  secret_id = "restic-password-cheddar"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "mumble_password" {
  secret_id = "mumble-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "pagerduty_key" {
  secret_id = "pagerduty-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "cheddar" {
  for_each = toset([
    google_secret_manager_secret.restic_password_cheddar.secret_id,
    google_secret_manager_secret.mumble_password.secret_id,
    google_secret_manager_secret.pagerduty_key.secret_id,
    google_secret_manager_secret.mail_ses_password.secret_id,
    google_secret_manager_secret.mail_userdb.secret_id,
  ])
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.instance_cheddar.email}"
}
