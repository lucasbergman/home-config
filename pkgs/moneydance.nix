{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  openjdk21,
  openjfx21,
  jvmFlags ? [ ],
}:
let
  jdk = openjdk21.override { enableJavaFX = true; };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "moneydance";
  version = "2024.1_5118";

  src = fetchzip {
    url = "https://infinitekind.com/stabledl/2024_5118/moneydance-linux.tar.gz";
    hash = "sha256-wwSb3CuhuXB4I9jq+TpLPbd1k9UzqQbAaZkGKgi+nns=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [
    jdk
    openjfx21
  ];

  dontConfigure = true;
  dontUnpack = true;
  dontBuild = true;
  dontFixup = true;

  # Note the double escaping in the call to makeWrapper. The escapeShellArgs
  # call quotes each element of the flags list as a word[1] and returns a
  # space-separated result; the escapeShellArg call quotes that result as a
  # single word to pass to --add-flags. The --add-flags implementation[2]
  # loops over the words in its argument.
  #
  # 1. https://www.gnu.org/software/bash/manual/html_node/Word-Splitting.html
  # 2. https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
  installPhase =
    let
      finalJvmFlags = [
        "-client"
        "--add-modules"
        "javafx.swing,javafx.controls,javafx.graphics"
        "-classpath"
        "${placeholder "out"}/libexec/*"
      ] ++ jvmFlags ++ [ "Moneydance" ];
    in
    ''
      runHook preInstall

      mkdir -p $out/libexec $out/bin
      cp -p $src/lib/* $out/libexec/
      makeWrapper ${jdk}/bin/java $out/bin/moneydance \
        --add-flags ${lib.escapeShellArg (lib.escapeShellArgs finalJvmFlags)}

      runHook postInstall
    '';

  passthru = {
    inherit jdk;
  };

  meta = {
    homepage = "https://infinitekind.com/moneydance";
    description = "An easy to use and full-featured personal finance app that doesn't compromise your privacy";
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    license = lib.licenses.unfree;
    platforms = jdk.meta.platforms;
  };
})
