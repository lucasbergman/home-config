{ lib, ... }:
{
  resource.google_project_service.project = {
    service = "secretmanager.googleapis.com";
    disable_on_destroy = true;
  };

  resource.google_secret_manager_secret = {
    mullvad_account = {
      secret_id = "mullvad-account";
      replication = {
        auto = { };
      };
    };

    nebula_ca_key = {
      secret_id = "nebula-ca-key";
      replication = {
        auto = { };
      };
    };

    rats_api_key = {
      secret_id = "rats-api-key";
      replication = {
        auto = { };
      };
    };
  }
  // (
    let
      hosts = [
        "spot"
        "hedwig"
        "snowball"
        "cheddar"
        "pinchy"
      ];
      mkSecret = name: {
        secret_id = name;
        replication = {
          auto = { };
        };
      };
    in
    lib.listToAttrs (
      lib.concatMap (host: [
        {
          name = "nebula_cert_${host}";
          value = mkSecret "nebula-cert-${host}";
        }
        {
          name = "nebula_key_${host}";
          value = mkSecret "nebula-key-${host}";
        }
      ]) hosts
    )
  );
}
