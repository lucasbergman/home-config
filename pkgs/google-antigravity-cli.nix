{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "google-antigravity-cli";
  version = "1.5.3-6604829099950080";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}/linux-x64/cli_linux_x64.tar.gz";
    hash = "sha256-G0hQWZzOc6F/lP+0It87+VMVMbd9vdxAwaQ14MLBaAc=";
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
