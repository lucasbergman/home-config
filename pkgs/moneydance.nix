{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  dpkg, # to unpack the deb file
  jdk17, # OpenJDK
}: let
  version = "5064-2023.3";
  hash = "sha256-t1jBZJ2sL0YDx9915UWgpCzKnpNq1Qz5i7ygGXDI5dk=";
in
  stdenv.mkDerivation {
    pname = "moneydance";
    inherit version;

    src = fetchurl {
      # TODO: Find a stable URL per version
      url = "https://infinitekind.com/stabledl/current/moneydance_linux_amd64.deb";
      inherit hash;
    };

    nativeBuildInputs = [dpkg];
    buildInputs = [jdk17 makeWrapper];

    dontConfigure = true;
    dontUnpack = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = let
      flags = lib.strings.escapeShellArgs [
        "-client"
        "-classpath"
        "${placeholder "out"}/libexec/*"
        "Moneydance"
      ];
    in ''
      runHook preInstall

      mkdir -p $out $out/bin
      dpkg -x $src $out
      mv $out/opt/Moneydance/lib $out/libexec
      rm -rf $out/opt
      makeWrapper ${jdk17}/bin/java $out/bin/moneydance --add-flags "${flags}"

      runHook postInstall
    '';

    meta = {
      homepage = "https://infinitekind.com/moneydance";
      description = "Moneydance is an easy to use and full-featured personal finance app that doesn't compromise your privacy";
      sourceProvenance = [lib.sourceTypes.binaryBytecode];
      license = lib.licenses.unfree;
      platforms = lib.platforms.all;
    };
  }
