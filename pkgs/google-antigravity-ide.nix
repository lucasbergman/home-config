{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
}:

let
  version = "2.0.3-6242596486512640";
  hash = "sha256-ALX9cJ/vAsn4GrTt136NW6+LhYQsxlT6AW19BJLN6AM=";
  weirdURLHash = "j0qc3";

  unwrapped = stdenv.mkDerivation {
    pname = "google-antigravity-ide-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://edgedl.me.gvt1.com/edgedl/release2/${weirdURLHash}/antigravity/stable/${version}/linux-x64/Antigravity%20IDE.tar.gz";
      inherit hash;
    };

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/google-antigravity-ide
      cp -r . $out/share/google-antigravity-ide/
      runHook postInstall
    '';
  };

in
buildFHSEnv {
  name = "google-antigravity-ide";

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
      xorg.libX11
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXScrnSaver
      xorg.libXtst
      xorg.libxcb
    ];

  # chrome-sandbox requires setuid root; --no-sandbox skips that requirement
  runScript = "${unwrapped}/share/google-antigravity-ide/antigravity-ide --no-sandbox";

  meta = {
    homepage = "https://antigravity.google/";
    description = "Google Antigravity IDE";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ lib.maintainers.lucasbergman ];
    mainProgram = "google-antigravity-ide";
  };
}
