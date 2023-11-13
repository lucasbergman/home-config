{
  mypkgs,
  nixpkgs,
  ...
}: {
  imports = [
    ../../../common/unifi.nix

    ./monitoring.nix
    ./plex.nix
  ];

  slb.unifi = let
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
    # TODO: Consider setting initialJavaHeapSize and/or maximumJavaHeapSize
    # after doing some measurement
    extraJvmOptions = [
      "-javaagent:${mypkgs.prometheus-jmx}/libexec/jmx_prometheus_javaagent.jar=[::1]:8444:${jmxPrometheusConfig}"
    ];
  };
}
