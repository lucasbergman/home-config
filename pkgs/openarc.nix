{
  lib,
  fetchurl,
  makeWrapper,
  stdenv,

  jansson,
  libidn2,
  libmilter,
  openssl,
  pkg-config,
  python3,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "openarc";
  version = "1.2.2";

  src = fetchurl {
    url = "https://github.com/flowerysong/OpenARC/releases/download/v${finalAttrs.version}/openarc-${finalAttrs.version}.tar.gz";
    hash = "sha256-NxHtgL12V2ga3sMhjkAejeTXfmqT1h2kwld4kc+iTho=";
  };

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    jansson
    libidn2
    libmilter
    openssl
  ];

  configureFlags = [ "--with-libjansson" ];

  postInstall = ''
    wrapProgram $out/bin/openarc-keygen \
      --prefix PATH : ${
        lib.makeBinPath [
          openssl
          python3
        ]
      }
  '';

  meta = {
    homepage = "https://github.com/flowerysong/OpenARC";
    description = "OpenARC is an open source library and filter for adding Authenticated Received Chain (ARC) support (RFC 8617) to email messages";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    license = lib.licenses.bsd2;
    maintainers = [ lib.maintainers.lucasbergman ];
  };
})
