resource "google_secret_manager_secret" "mail_ses_password" {
  secret_id = "mail-ses-password"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "mail_userdb" {
  secret_id = "mail-userdb"
  replication {
    automatic = true
  }
}
