resource "google_project_service" "project" {
  service = "secretmanager.googleapis.com"
}
