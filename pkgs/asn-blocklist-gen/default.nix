{
  lib,
  python3,
}:

python3.pkgs.buildPythonApplication {
  pname = "asn-blocklist-gen";
  version = "0.1.0";
  format = "other";

  src = ./.;

  nativeCheckInputs = [ python3.pkgs.mypy ];

  installPhase = ''
    install -Dm755 asn-blocklist-gen.py $out/bin/asn-blocklist-gen
  '';

  checkPhase = ''
    runHook preCheck
    mypy --strict .
    runHook postCheck
  '';

  meta = {
    description = "Tool to generate nftables blocklist from ASN list";
    mainProgram = "asn-blocklist-gen";
    maintainers = with lib.maintainers; [ lucasbergman ];
  };
}
