{ lib, ... }:
{
  resource.google_project_service.aiplatform = {
    service = "aiplatform.googleapis.com";
    disable_on_destroy = true;
  };

  resource.google_service_account.hermes = {
    account_id = "hermes";
    display_name = "Hermes Agent service account";
  };

  resource.google_project_iam_member.hermes_vertex_user = {
    project = lib.tfRef "var.gcp_project";
    role = "roles/aiplatform.user";
    member = "serviceAccount:\${google_service_account.hermes.email}";
  };
}
