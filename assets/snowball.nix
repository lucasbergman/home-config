{ lib, ... }:
{
  # Create an instance-level GCP service account and make it a member of
  # IAM roles to enable DNS writes for ACME-generated certificates, log
  # shipping, and writing backups.

  resource.google_service_account.instance_snowball = {
    account_id = "instance-snowball";
    display_name = "snowball server instance account";
  };

  resource.google_project_iam_member.snowball_acme_dns = {
    project = lib.tfRef "var.gcp_project";
    role = lib.tfRef "google_project_iam_custom_role.acme_dns.name";
    member = "serviceAccount:\${google_service_account.instance_snowball.email}";
  };

  resource.google_project_iam_member.snowball_log_writer = {
    project = lib.tfRef "var.gcp_project";
    role = "roles/logging.logWriter";
    member = "serviceAccount:\${google_service_account.instance_snowball.email}";
  };

  resource.google_storage_bucket_iam_member.snowball_backup = {
    bucket = lib.tfRef "google_storage_bucket.backup.name";
    role = "roles/storage.objectAdmin";
    member = "serviceAccount:\${google_service_account.instance_snowball.email}";
  };

  resource.google_secret_manager_secret.restic_password_snowball = {
    secret_id = "restic-password-snowball";
    replication = {
      auto = { };
    };
  };

  resource.google_secret_manager_secret_iam_member =
    let
      mkMember = secret: {
        secret_id = lib.tfRef "google_secret_manager_secret.${secret}.secret_id";
        role = "roles/secretmanager.secretAccessor";
        member = "serviceAccount:\${google_service_account.instance_snowball.email}";
      };
    in
    {
      snowball_restic_password_snowball = mkMember "restic_password_snowball";
    };
}
