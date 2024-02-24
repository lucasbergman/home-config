resource "google_dns_record_set" "bergmans_a_trackphotos" {
  managed_zone = google_dns_managed_zone.bergmans.name
  name         = "trackphotos.bergmans.us."
  type         = "A"
  rrdatas      = ["157.230.186.237"]
  ttl          = 300
}

# Create an instance-level GCP service account and make it a member of
# IAM roles to enable DNS writes for ACME-generated certificates, etc

resource "google_service_account" "instance_trackphotos" {
  account_id   = "instance-trackphotos"
  display_name = "Track Photos server instance account"
}

resource "google_project_iam_member" "trackphotos_acme_dns" {
  project = var.gcp_project
  role    = google_project_iam_custom_role.acme_dns.name
  member  = "serviceAccount:${google_service_account.instance_trackphotos.email}"
}

resource "google_service_account_key" "instance_trackphotos" {
  service_account_id = google_service_account.instance_trackphotos.id
}

resource "local_sensitive_file" "instance_trackphotos" {
  file_permission = "0600"
  content_base64  = google_service_account_key.instance_trackphotos.private_key
  filename        = "${path.module}/trackphotos-instance-private-key.json"
}

resource "google_secret_manager_secret" "trackphotos_root_password" {
  secret_id = "trackphotos-root-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "trackphotos" {
  for_each = toset([
    google_secret_manager_secret.trackphotos_root_password.secret_id,
  ])
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.instance_trackphotos.email}"
}
