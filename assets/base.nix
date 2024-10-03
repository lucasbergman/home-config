{ lib, ... }:
{
  terraform = {
    required_providers = {
      aws.source = "hashicorp/aws";
      google.source = "hashicorp/google";
      linode.source = "linode/linode";
      local.source = "hashicorp/local";
    };

    backend.gcs = {
      bucket = "bergmans-services-home";
      prefix = "terraform/state";
    };
  };

  provider = {
    aws = {
      region = lib.tfRef "var.aws_region";
      access_key = lib.tfRef "var.aws_access_key_id";
      secret_key = lib.tfRef "var.aws_secret_key";
    };

    google = {
      project = lib.tfRef "var.gcp_project";
    };

    linode = {
      token = lib.tfRef "var.linode_token";
    };
  };
}
