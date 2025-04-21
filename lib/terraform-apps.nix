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
  terraform-plan = {
    type = "app";
    program = "${plan}/bin/terraform-plan";
  };
  terraform-apply = {
    type = "app";
    program = "${apply}/bin/terraform-apply";
  };
}
