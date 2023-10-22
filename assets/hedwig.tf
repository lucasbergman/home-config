# Create an instance-level GCP service account and make it a member of
# IAM roles to enable DNS writes for ACME-generated certificates, log
# shipping, and writing backups.

resource "google_service_account" "instance_hedwig" {
  account_id   = "instance-hedwig"
  display_name = "Hedwig server instance account"
}

resource "google_project_iam_member" "hedwig_acme_dns" {
  project = var.gcp_project
  role    = google_project_iam_custom_role.acme_dns.name
  member  = "serviceAccount:${google_service_account.instance_hedwig.email}"
}

resource "google_project_iam_member" "hedwig_log_writer" {
  project = var.gcp_project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.instance_hedwig.email}"
}

resource "google_storage_bucket_iam_member" "hedwig_backup" {
  bucket = google_storage_bucket.backup.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.instance_hedwig.email}"
}

resource "google_service_account_key" "instance_hedwig" {
  service_account_id = google_service_account.instance_hedwig.id
}

resource "local_sensitive_file" "instance_hedwig" {
  file_permission = "0600"
  content_base64  = google_service_account_key.instance_hedwig.private_key
  filename        = "${path.module}/hedwig-instance-private-key.json"
}
