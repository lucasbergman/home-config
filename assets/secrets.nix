{ ... }:
{
  resource.google_project_service.project = {
    service = "secretmanager.googleapis.com";
    disable_on_destroy = true;
  };

  resource.google_secret_manager_secret.mullvad_account = {
    secret_id = "mullvad-account";
    replication = {
      auto = { };
    };
  };

  resource.google_secret_manager_secret.nebula_ca_key = {
    secret_id = "nebula-ca-key";
    replication = {
      auto = { };
    };
  };

  resource.google_secret_manager_secret.rats_api_key = {
    secret_id = "rats-api-key";
    replication = {
      auto = { };
    };
  };
}
