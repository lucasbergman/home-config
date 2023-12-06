{
  mypkgs,
  nixpkgs,
  ...
}: {
  imports = [
    ./monitoring.nix
    ./plex.nix
  ];

  services.unifi = let
    # TODO: The excludeObjectNames config isn't working
    jmxPrometheusConfig = nixpkgs.writeText "jmx-prometheus.yml" (builtins.toJSON {
      excludeObjectNames = ["Tomcat:*"];
      lowercaseOutputName = true;
      lowercaseOutputLabelNames = true;
    });
  in {
    enable = true;
    unifiPackage = mypkgs.unifi;
    jrePackage = nixpkgs.jdk17_headless;
    maximumJavaHeapSize = 1024; # TODO: Might be possible to decrease this
    extraJvmOptions = [
      "-javaagent:${mypkgs.prometheus-jmx}/libexec/jmx_prometheus_javaagent.jar=[::1]:8444:${jmxPrometheusConfig}"
    ];
  };
}
