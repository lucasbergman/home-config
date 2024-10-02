{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "0.19.0";
  hash = "sha256-+1BwAZlsmvOHCcEQ3jJRf3WSyBi7M+GLxf6U4HbSTB8=";
in
stdenv.mkDerivation {
  pname = "jmx-prometheus-javaagent";
  inherit version;

  src =
    let
      jarName = "jmx_prometheus_javaagent-${version}.jar";
    in
    fetchurl {
      url = "mirror://maven/io/prometheus/jmx/jmx_prometheus_javaagent/${version}/${jarName}";
      inherit hash;
    };

  nativeBuildInputs = [ ];
  buildInputs = [ ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/libexec
    cp $src $out/libexec/jmx_prometheus_javaagent.jar
  '';

  meta = {
    homepage = "https://github.com/prometheus/jmx_exporter";
    description = "A process for exposing JMX Beans via HTTP for Prometheus consumption";
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
