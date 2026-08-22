{
  pkgs,
  ...
}:
let
  certDomain = "gw.bergman.house";
  sshKeyDir = "/persist/var/lib/acme/.ssh";
  sshKeyPath = "${sshKeyDir}/id_unifi_deploy";
  sshOpts = "-i ${sshKeyPath} -o UserKnownHostsFile=/var/lib/acme/.ssh/known_hosts";
in
{
  # Ensure the .ssh directories exist with appropriate permissions for the acme user
  systemd.tmpfiles.rules = [
    "d ${sshKeyDir} 0700 acme acme -"
    "d /var/lib/acme/.ssh 0700 acme acme -"
  ];

  # Get a cert for gw.bergman.house, and deploy it to the UCG Ultra
  security.acme.certs."${certDomain}" = {
    postRun = ''
      ${pkgs.openssh}/bin/scp ${sshOpts} \
        fullchain.pem root@${certDomain}:/data/unifi-core/config/unifi-core.crt

      ${pkgs.openssh}/bin/scp ${sshOpts} \
        key.pem root@${certDomain}:/data/unifi-core/config/unifi-core.key

      ${pkgs.openssh}/bin/ssh ${sshOpts} \
        root@${certDomain} "systemctl restart unifi-core"
    '';
  };
}
