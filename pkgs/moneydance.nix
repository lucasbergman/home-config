{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  openjdk23,
  wrapGAppsHook3,
  jvmFlags ? [ ],
}:
let
  jdk = openjdk23.override {
    enableJavaFX = true;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "moneydance";
  version = "2024.1_5118";

  src = fetchzip {
    url = "https://infinitekind.com/stabledl/2024_5118/moneydance-linux.tar.gz";
    hash = "sha256-wwSb3CuhuXB4I9jq+TpLPbd1k9UzqQbAaZkGKgi+nns=";
  };

  nativeBuildInputs = [
    makeWrapper
    wrapGAppsHook3
  ];
  buildInputs = [ jdk ];
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec $out/bin
    cp -p $src/lib/* $out/libexec/

    runHook postInstall
  '';

  postFixup =
    let
      shellSafe = s: (builtins.match "[[:alnum:],._+:@%/=-]+" s) != null;
      finalJvmFlags =
        [
          "-client"
          "--add-modules"
          "javafx.swing,javafx.controls,javafx.graphics"
          "-classpath"
          "${placeholder "out"}/libexec/*"
        ]
        ++ (
          # We must use wrapGAppsHook (since Java GUIs on Linux use GTK), but that
          # uses makeBinaryWrapper, which doesn't support flags that need quoting:
          # <https://github.com/NixOS/nixpkgs/issues/330471>.
          assert lib.assertMsg (lib.all shellSafe jvmFlags)
            "JVM flags that need shell quoting are not supported";
          jvmFlags
        )
        ++ [ "Moneydance" ];
    in
    ''
      # This is in postFixup because gappsWrapperArgs is generated in preFixup
      makeWrapper ${jdk}/bin/java $out/bin/moneydance \
        "''${gappsWrapperArgs[@]}" \
        --add-flags ${lib.escapeShellArg (lib.strings.concatStringsSep " " finalJvmFlags)}
    '';

  passthru = {
    inherit jdk;
  };

  meta = {
    homepage = "https://infinitekind.com/moneydance";
    changelog = "https://infinitekind.com/stabledl/2024_5118/changelog.txt";
    description = "Easy to use and full-featured personal finance app that doesn't compromise your privacy";
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    license = lib.licenses.unfree;
    # Darwin refers to Zulu Java, which breaks the evaluation of this derivation
    # for some reason
    #
    # https://github.com/NixOS/nixpkgs/pull/306372#issuecomment-2111688236
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.lucasbergman ];
  };
})
