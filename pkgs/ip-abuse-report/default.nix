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

  installPhase = ''
    install -Dm755 ip-abuse-report.py $out/bin/ip-abuse-report
  '';

  meta = {
    description = "Tool to map IPs to ASNs using local BGP data";
    mainProgram = "ip-abuse-report";
    maintainers = with lib.maintainers; [ lucasbergman ];
  };
}
