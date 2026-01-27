{
  lib,
  python3,
}:

python3.pkgs.buildPythonApplication {
  pname = "ip-abuse-report";
  version = "0.1.0";
  format = "other";

  src = ./.;

  propagatedBuildInputs = [ python3.pkgs.pytricia ];
  nativeCheckInputs = [ python3.pkgs.mypy ];

  installPhase = ''
    install -Dm755 ip-abuse-report.py $out/bin/ip-abuse-report
    install -Dm755 add-asn-info.py $out/bin/add-asn-info
  '';

  checkPhase = ''
    runHook preCheck
    mypy --strict .
    runHook postCheck
  '';

  meta = {
    description = "Tools for ASN-based abuse reporting";
    mainProgram = "ip-abuse-report";
    maintainers = with lib.maintainers; [ lucasbergman ];
  };
}
