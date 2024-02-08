resource "google_project_service" "project" {
  service = "secretmanager.googleapis.com"
}

resource "google_secret_manager_secret" "mullvad_account" {
  secret_id = "mullvad-account"
  replication {
    auto {}
  }
}
