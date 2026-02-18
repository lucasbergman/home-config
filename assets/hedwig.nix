{ lib, ... }:
{
  # Create an instance-level GCP service account and make it a member of
  # IAM roles to enable DNS writes for ACME-generated certificates, log
  # shipping, and writing backups.

  resource.google_service_account.instance_hedwig = {
    account_id = "instance-hedwig";
    display_name = "Hedwig server instance account";
  };

  resource.google_project_iam_member.hedwig_acme_dns = {
    project = lib.tfRef "var.gcp_project";
    role = lib.tfRef "google_project_iam_custom_role.acme_dns.name";
    member = "serviceAccount:\${google_service_account.instance_hedwig.email}";
  };

  resource.google_project_iam_member.hedwig_log_writer = {
    project = lib.tfRef "var.gcp_project";
    role = "roles/logging.logWriter";
    member = "serviceAccount:\${google_service_account.instance_hedwig.email}";
  };

  resource.google_storage_bucket_iam_member.hedwig_backup = {
    bucket = lib.tfRef "google_storage_bucket.backup.name";
    role = "roles/storage.objectAdmin";
    member = "serviceAccount:\${google_service_account.instance_hedwig.email}";
  };

  resource.google_service_account_key.instance_hedwig = {
    service_account_id = lib.tfRef "google_service_account.instance_hedwig.id";
  };

  resource.local_sensitive_file.instance_hedwig = {
    file_permission = "0600";
    content_base64 = lib.tfRef "google_service_account_key.instance_hedwig.private_key";
    filename = "\${path.module}/hedwig-instance-private-key.json";
  };

  resource.google_secret_manager_secret.restic_password_hedwig = {
    secret_id = "restic-password-hedwig";
    replication = {
      auto = { };
    };
  };

  resource.google_secret_manager_secret.unpoller_password_hedwig = {
    secret_id = "unpoller-password-hedwig";
    replication = {
      auto = { };
    };
  };

  resource.google_secret_manager_secret.mullvad_wg_key_hedwig = {
    secret_id = "mullvad-wg-key-hedwig";
    replication = {
      auto = { };
    };
  };

  resource.google_secret_manager_secret.home_assistant_secrets_file = {
    secret_id = "home-assistant-secrets-file";
    replication = {
      auto = { };
    };
  };

  resource.google_secret_manager_secret.nebula_host_key_hedwig = {
    secret_id = "nebula-host-key-hedwig";
    replication = {
      auto = { };
    };
  };

  resource.google_secret_manager_secret_iam_member =
    let
      mkMember = secret: {
        secret_id = lib.tfRef "google_secret_manager_secret.${secret}.secret_id";
        role = "roles/secretmanager.secretAccessor";
        member = "serviceAccount:\${google_service_account.instance_hedwig.email}";
      };
    in
    {
      hedwig_restic_password_hedwig = mkMember "restic_password_hedwig";
      hedwig_unpoller_password_hedwig = mkMember "unpoller_password_hedwig";
      hedwig_mullvad_wg_key_hedwig = mkMember "mullvad_wg_key_hedwig";
      hedwig_mullvad_account = mkMember "mullvad_account";
      hedwig_home_assistant_secrets_file = mkMember "home_assistant_secrets_file";
      hedwig_nebula_host_key_hedwig = mkMember "nebula_host_key_hedwig";
    };
}
