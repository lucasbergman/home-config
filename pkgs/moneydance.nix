{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  dpkg, # to unpack the deb file
  openjdk21, # OpenJDK
  openjfx21, # OpenJFX
}: let
  version = "2023.3_5064";
  hash = "sha256-t1jBZJ2sL0YDx9915UWgpCzKnpNq1Qz5i7ygGXDI5dk=";
in
  stdenv.mkDerivation rec {
    pname = "moneydance";
    inherit version;

    src = fetchurl {
      url = "https://infinitekind.com/stabledl/${version}/moneydance_linux_amd64.deb";
      inherit hash;
    };

    jdk = openjdk21.override {
      headless = false;
      enableJavaFX = true;
      openjfx = openjfx21;
    };

    nativeBuildInputs = [dpkg];
    buildInputs = [jdk makeWrapper];

    dontConfigure = true;
    dontUnpack = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = let
      flags = lib.strings.escapeShellArgs [
        "-client"
        "--add-modules"
        "javafx.swing,javafx.controls,javafx.graphics"
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
      makeWrapper ${jdk}/bin/java $out/bin/moneydance --add-flags "${flags}"

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
