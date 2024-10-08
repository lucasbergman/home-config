{
  config,
  lib,
  mypkgs,
  pkgs,
  ...
}:
{
  options.slb.gcplogs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to enable log shipping to GCP";
      default = false;
    };

    location = lib.mkOption {
      type = lib.types.str;
      description = "Location string to use when shipping logs";
      example = "us:central";
    };

    included-units = lib.mkOption {
      type = with lib.types; listOf str;
      description = ''
        List of systemd units to include when shipping logs. The default
        value, the empty list, means that all units get their logs shipped,
        which might be unbearably noisy.
      '';
      default = [ ];
    };
  };

  config =
    let
      cfg = config.slb.gcplogs;
    in
    lib.mkIf cfg.enable {
      systemd.services.fluentbit-gcplogs =
        let
          # This config format is a bummer, but I can't figure out how to use
          # YAML-format config to specify an input propery like systemd_filter
          # more than once. (Setting it to be array-valued is a parse error.)
          mkUnitFilters = lib.concatMapStringsSep "\n" (unit: "    systemd_filter _SYSTEMD_UNIT=${unit}");
          configFile = pkgs.writeText "fluentbit.conf" ''
            [INPUT]
                Name systemd
            ${mkUnitFilters cfg.included-units}

            [OUTPUT]
                Name stackdriver
                Match *
                resource generic_node
                namespace global
                google_service_credentials /run/gcp-instance-creds.json
                location ${cfg.location}
                node_id ${config.networking.hostName}.${config.networking.domain}
          '';
        in
        {
          wantedBy = [ "multi-user.target" ];
          after = [
            "instance-key.service"
            "network.target"
          ];
          requires = [ "network.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.fluent-bit}/bin/fluent-bit --config=${configFile}";
            Restart = "always";
          };
        };
    };
}
