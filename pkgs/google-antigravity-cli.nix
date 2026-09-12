{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "google-antigravity-cli";
  version = "1.2.1-5123043593420800";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}/linux-x64/cli_linux_x64.tar.gz";
    hash = "sha256-aixT22xoH8EU+aHkmee0dxNXqyhSJC5WrL1DGX1IB/k=";
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
