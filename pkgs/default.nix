{
  pkgs,
  ...
}:
{
  asn-blocklist-gen = pkgs.callPackage ./asn-blocklist-gen { };
  gcp-secret-subst = pkgs.callPackage ./gcp-secret-subst { };
  google-antigravity-cli = pkgs.callPackage ./google-antigravity-cli.nix { };
  google-antigravity-ide = pkgs.callPackage ./google-antigravity-ide.nix { };
  ip-abuse-report = pkgs.callPackage ./ip-abuse-report { };
  moneydance = pkgs.callPackage ./moneydance.nix { };
  openarc = pkgs.callPackage ./openarc.nix { };
  prometheus-jmx = pkgs.callPackage ./prometheus-jmx.nix { };
  spamass-milter = pkgs.callPackage ./spamass-milter { };
}
