{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "google-antigravity-cli";
  version = "1.0.2-6109799369277440";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}/linux-x64/cli_linux_x64.tar.gz";
    hash = "sha512-Ex9fODBAgpNvgeyP2pqjkRIxCQ9ao7J+rVfD3l2VwO+VsoGmwC2By4K+uEmEVQBP27YvDwknPVyEu7XnoPMwhg==";
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
