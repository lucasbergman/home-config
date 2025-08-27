{
  pkgs,
  terraform,
  terranix,
  extraModules ? [ ],
}:
let
  terraformConfig = terranix.lib.terranixConfiguration {
    inherit pkgs;
    modules = [ ../assets ] ++ extraModules;
  };
  config = pkgs.writeShellApplication {
    name = "terraform-config";
    text = ''
      set -e
      basedir=$(git rev-parse --show-toplevel)
      cd "$basedir"/assets
      config_hash=$(nix hash file --type sha1 --base32 ${terraformConfig})
      cat ${terraformConfig} > "config-''${config_hash}.tf.json"
      echo "generated Terraform config: config-''${config_hash}.tf.json"
    '';
  };
  plan = pkgs.writeShellApplication {
    name = "terraform-plan";
    text = ''
      set -e
      basedir=$(git rev-parse --show-toplevel)
      cd "$basedir"/assets
      config_hash=$(nix hash file --type sha1 --base32 ${terraformConfig})
      cat ${terraformConfig} > "config-''${config_hash}.tf.json"
      ${terraform}/bin/terraform plan -out="plan-''${config_hash}"
      rm "config-''${config_hash}.tf.json"
    '';
  };
  apply = pkgs.writeShellApplication {
    name = "terraform-apply";
    text = ''
      set -e
      basedir=$(git rev-parse --show-toplevel)
      cd "$basedir"/assets
      config_hash=$(nix hash file --type sha1 --base32 "${terraformConfig}")
      if [ ! -f "plan-''${config_hash}" ]; then
        echo "fatal: No plan found for config hash: ''${config_hash}" >&2
        exit 1
      fi
      exec ${terraform}/bin/terraform apply "plan-''${config_hash}"
    '';
  };
in
{
  terraform-config = {
    type = "app";
    program = "${config}/bin/terraform-config";
    meta.description = "Generate Terraform configuration from Terranix modules";
  };
  terraform-plan = {
    type = "app";
    program = "${plan}/bin/terraform-plan";
    meta.description = "Create Terraform execution plan from Terranix configuration";
  };
  terraform-apply = {
    type = "app";
    program = "${apply}/bin/terraform-apply";
    meta.description = "Apply Terraform execution plan to infrastructure";
  };
}
