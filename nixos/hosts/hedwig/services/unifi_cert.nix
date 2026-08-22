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
  systemd.tmpfiles.rules = [
    "d ${sshKeyDir} 0700 acme acme -"
    "d /var/lib/acme/.ssh 0700 acme acme -"
  ];

  security.acme.certs."${certDomain}" = {
    # UniFi (and Java keystore?) hates EC keys
    keyType = "rsa2048";

    # It seems like unifi-core watches its config files with inotify,
    # so we have to turn it off while we scribble over them
    postRun = ''
      ${pkgs.openssh}/bin/ssh ${sshOpts} \
        root@${certDomain} "systemctl stop unifi-core"
      ${pkgs.openssh}/bin/scp ${sshOpts} \
        fullchain.pem root@${certDomain}:/data/unifi-core/config/unifi-core.crt
      ${pkgs.openssh}/bin/scp ${sshOpts} \
        key.pem root@${certDomain}:/data/unifi-core/config/unifi-core.key
      ${pkgs.openssh}/bin/scp ${sshOpts} \
        fullchain.pem root@${certDomain}:/data/unifi-core/config/unifi-core-direct.crt
      ${pkgs.openssh}/bin/scp ${sshOpts} \
        key.pem root@${certDomain}:/data/unifi-core/config/unifi-core-direct.key
      ${pkgs.openssh}/bin/ssh ${sshOpts} \
        root@${certDomain} "systemctl start unifi-core"
    '';
  };
}
