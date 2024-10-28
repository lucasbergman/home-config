{ ... }:
{
  variable = {
    aws_region = {
      description = "AWS region";
      type = "string";
      default = "us-east-2";
    };

    aws_access_key_id = {
      description = "AWS access key";
      type = "string";
    };

    aws_secret_key = {
      description = "AWS secret key";
      type = "string";
    };

    gcp_project = {
      description = "GCP project name";
      type = "string";
      default = "bergmans-services";
    };

    linode_token = {
      description = "Linode API token";
      type = "string";
    };

    linode_region = {
      description = "Region to place instances; see https://api.linode.com/v4/regions";
      type = "string";
      default = "us-central";
    };

    linode_type = {
      description = "Instance type; see https://api.linode.com/v4/linode/types";
      type = "string";
      default = "g6-standard-2";
    };

    slb_house_ipv4 = {
      description = "IPv4 address of the legacy house server";
      type = "string";
      default = "98.227.21.195";
    };
  };
}
