{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "google-antigravity-cli";
  version = "1.1.4-6277569641840640";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}/linux-x64/cli_linux_x64.tar.gz";
    hash = "sha512-oIih8jHYVltmc87Nhlb8NQTknInpxrjEEWk3tf5wacjc+6eLuyvFwP+Oh7pk/iG2PbcAHjpXlFBJJ9rZ6J2pcw==";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp antigravity $out/bin/agy
    runHook postInstall
  '';

  meta = {
    homepage = "https://antigravity.google/";
    description = "Google Antigravity CLI";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ lib.maintainers.lucasbergman ];
    mainProgram = "agy";
  };
}
