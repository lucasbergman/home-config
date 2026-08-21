{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
}:

let
  version = "2.9.1-4871453687021568";
  hash = "sha256-AW2/akLFpJqsT6QD16iSBKPHyTN5nJXsuRrCwW+jTe0=";

  unwrapped = stdenv.mkDerivation {
    pname = "google-antigravity-hub-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/${version}/linux-x64/Antigravity.tar.gz";
      inherit hash;
    };

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/google-antigravity-hub
      cp -r . $out/share/google-antigravity-hub/
      runHook postInstall
    '';
  };

in
buildFHSEnv {
  name = "google-antigravity-hub";

  targetPkgs =
    pkgs: with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libdrm
      libgbm
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      libx11
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxscrnsaver
      libxtst
      libxcb
    ];

  # chrome-sandbox requires setuid root; --no-sandbox skips that requirement
  runScript = "${unwrapped}/share/google-antigravity-hub/antigravity --no-sandbox";

  meta = {
    homepage = "https://antigravity.google/";
    description = "Google Antigravity Hub";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ lib.maintainers.lucasbergman ];
    mainProgram = "google-antigravity-hub";
  };
}
