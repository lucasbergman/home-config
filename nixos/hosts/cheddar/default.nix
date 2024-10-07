{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../common/cloudbackup.nix
    ../../common/gcplogs.nix
    ../../common/nginx.nix
    ../../common/global
    ../../common/users
    ../../linode
    ./hardware-configuration.nix
    ./services
  ];

  fileSystems."/data" = {
    device = "/dev/disk/by-label/data";
    fsType = "ext4";
  };

  networking = {
    hostName = "cheddar";
    domain = "bergmans.us";
  };

  slb.securenet = {
    enable = true;
    network = "bergnet";
    privateKeyPath = "/etc/bergmans-wg-key";
  };

  slb.backups = {
    gcsPath = "/cheddar";
    backupPaths = [ "/data" ];
    passwordSecretID = "projects/bergmans-services/secrets/restic-password-cheddar/versions/1";
  };

  slb.security.gcpInstanceKeyPath = ./gcp-instance-key.json;

  slb.gcplogs = {
    location = "linode";
    included-units = [
      "alertmanager.service"
      "dovecot2.service"
      "grafana.service"
      # TODO: Add matrix-synapse.service, but it's super noisy
      "murmur.service"
      "nginx.service"
      "nscd.service"
      "postfix.service"
      "prometheus-blackbox-exporter.service"
      "prometheus-node-exporter.service"
      "prometheus.service"
      "sshd.service"
      "systemd-journald.service"
      "systemd-logind.service"
      "systemd-networkd.service"
      "systemd-oomd.service"
      "systemd-resolved.service"
      "systemd-timesyncd.service"
      "systemd-udevd.service"
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
