{
  config,
  lib,
  pkgs,
  ...
}:
let
  myAddress = "10.7.1.2";
in
{
  services.prometheus =
    let
      promcfg = config.services.prometheus;
      unpollercfg = config.slb.unpoller;
      hasscfg = config.services.home-assistant.config;
    in
    {
      enable = true;
      retentionTime = "90d";
      listenAddress = myAddress;
      globalConfig = {
        scrape_timeout = "5s";
        evaluation_interval = "10s";
      };
      ruleFiles =
        let
          rulesAttrSet = import ./monitoring_rules.nix { inherit lib; };
        in
        [
          (builtins.toString (pkgs.writeText "rules.json" (builtins.toJSON rulesAttrSet)))
        ];

      scrapeConfigs = [
        {
          job_name = "node";
          scrape_interval = "10s";
          static_configs = [ { targets = [ "[::1]:${toString promcfg.exporters.node.port}" ]; } ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.+):(.*)$";
              target_label = "instance";
              replacement = "hedwig:$2";
            }
          ];
        }
        {
          job_name = "smart";
          static_configs = [ { targets = [ "[::1]:${toString promcfg.exporters.smartctl.port}" ]; } ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.+):(.*)$";
              target_label = "instance";
              replacement = "hedwig:$2";
            }
          ];
        }
        {
          job_name = "unifi";
          scrape_interval = "10s";
          static_configs = [ { targets = [ unpollercfg.prometheusListenAddr ]; } ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.+):(.*)$";
              target_label = "instance";
              replacement = "hedwig:$2";
            }
          ];
        }
        {
          job_name = "unifi_jvm";
          static_configs = [ { targets = [ "[::1]:8444" ]; } ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              regex = "(.+):(.*)$";
              target_label = "instance";
              replacement = "hedwig:$2";
            }
          ];
        }
        {
          job_name = "hass";
          static_configs = [ { targets = [ "[::1]:${toString hasscfg.http.server_port}" ]; } ];
          metrics_path = "/api/prometheus";
          relabel_configs = [
            {
              target_label = "instance";
              replacement = "hedwig:hass";
            }
          ];
        }
      ];

      alertmanagers = [
        {
          static_configs = [
            { targets = [ "${promcfg.alertmanager.listenAddress}:${toString promcfg.alertmanager.port}" ]; }
          ];
        }
      ];

      alertmanager = {
        enable = true;
        listenAddress = myAddress;
        webExternalUrl = "http://${myAddress}:${toString promcfg.alertmanager.port}";
        logLevel = "debug";

        extraFlags = [
          # Turn off HA/cluster mode. That's a good idea in single-server setups
          # anyway - might as well reduce one's attack surface - but I found out
          # that this wasn't the default in a stupid way. On a Linode VM with no
          # RFC 1918 private interface (only loopback and public), alertmanager
          # dies at startup saying "Failed to get final advertise address: No
          # private IP address found".
          "--cluster.listen-address=''"
        ];

        configuration = {
          global = {
            smtp_smarthost = "cheddar.internal.bergman.house:587";
            smtp_from = "alertmanager@bergmans.us";
          };
          route = {
            group_by = [
              "alertname"
              "cluster"
              "service"
            ];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "4h";
            receiver = "me-mail"; # default receiver
          };
          receivers = [
            {
              name = "me-mail";
              email_configs = [
                {
                  to = "lucas+alerts@bergmans.us";
                  tls_config.insecure_skip_verify = true;
                }
              ];
            }
          ];
        };
      };

      exporters = {
        node = {
          enable = true;
          listenAddress = "[::1]";
          enabledCollectors = [
            "systemd"
            "textfile"
          ];
          extraFlags = [
            "--collector.textfile.directory=/run/prometheus-node-exporter"
          ];
        };
        smartctl = {
          enable = true;
          listenAddress = "[::1]";
          devices = [
            "/dev/nvme0n1"
            "/dev/sda"
            "/dev/sdb"
            "/dev/sdc"
            "/dev/sdd"
            "/dev/sde"
          ];
        };
      };
    };

  systemd.services.prom-wan-ip-probe = {
    description = "STUN WAN IP and DNS match prober";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      RuntimeDirectory = "prometheus-node-exporter";
      RuntimeDirectoryPreserve = "yes";
    };
    path = with pkgs; [
      coreutils
      dnsutils
      gnused
      stuntman
    ];
    script = ''
      set -euo pipefail
      PROM_FILE="/run/prometheus-node-exporter/home_wan_ip.prom"
      TMP_FILE="$PROM_FILE.$$"

      WAN_IP=$(stunclient stun.l.google.com 19302 \
        | sed -n 's/.*Mapped address: \([0-9.]*\):.*/\1/p')
      DNS_IP=$(dig +short +time=3 +tries=2 @8.8.8.8 bergman.house A)

      MATCH=0
      if [ "$WAN_IP" = "$DNS_IP" ]; then
        MATCH=1
      fi

      cat <<EOF > "$TMP_FILE"
      # HELP home_wan_dns_match 1 if current WAN IP matches public DNS A record, 0 otherwise
      # TYPE home_wan_dns_match gauge
      home_wan_dns_match{wan_ip="$WAN_IP",dns_ip="$DNS_IP"} $MATCH
      EOF
      mv "$TMP_FILE" "$PROM_FILE"
    '';
  };

  systemd.timers.prom-wan-ip-probe = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "10m";
    };
  };

  users.groups.disk.members = [ "smartctl-exporter" ];

  slb.unpoller = {
    enable = true;
    unifiUrl = "https://192.168.101.1/";
    unifiUser = "unifipoller";
    unifiPasswordSecretID = "projects/bergmans-services/secrets/unpoller-password-hedwig/versions/1";
  };
}
