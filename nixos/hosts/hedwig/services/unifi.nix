{
  mypkgs,
  pkgs,
  ...
}: {
  systemd.services."unifi-usg-config" = {
    description = "write UniFi USG config file";
    wantedBy = ["multi-user.target"];
    before = ["unifi.service"];
    serviceConfig.Type = "oneshot";

    script = let
      configFile = pkgs.writeText "config.gateway.json" (
        builtins.toJSON (import ../conf/unifi.nix)
      );
      siteName = "default";
      targetDir = "/var/lib/unifi/data/sites/${siteName}";
    in ''
      if [[ ! -d ${targetDir} ]]; then
        install -d -m 0500 -o unifi -g unifi ${targetDir}
      fi
      rm -f ${targetDir}/config.gateway.json
      ln -f -s ${configFile} ${targetDir}/config.gateway.json
    '';
  };

  services.unifi = let
    # TODO: The excludeObjectNames config isn't working
    jmxPrometheusConfig = pkgs.writeText "jmx-prometheus.yml" (builtins.toJSON {
      excludeObjectNames = ["Tomcat:*"];
      lowercaseOutputName = true;
      lowercaseOutputLabelNames = true;
    });
  in {
    enable = true;
    unifiPackage = mypkgs.unifi;
    jrePackage = pkgs.jdk17_headless;
    maximumJavaHeapSize = 1024; # TODO: Might be possible to decrease this
    extraJvmOptions = [
      "-javaagent:${mypkgs.prometheus-jmx}/libexec/jmx_prometheus_javaagent.jar=[::1]:8444:${jmxPrometheusConfig}"
    ];
  };
}
