{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../common/global
    ../../common/users
    ../../common/users/hermes.nix
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

  slb.nebula.enable = true;

  slb.backups = {
    gcsPath = "/cheddar";
    backupPaths = [ "/data" ];
    passwordSecretID = "projects/bergmans-services/secrets/restic-password-cheddar/versions/1";
  };

  slb.nginx.enable = true;

  slb.gcplogs = {
    enable = true;
    location = "linode";
    included-units = [
      "alertmanager.service"
      "dovecot.service"
      "grafana.service"
      # TODO: Add matrix-synapse.service, but it's super noisy
      "murmur.service"
      "nginx.service"
      "nscd.service"
      "postfix.service"
      "prometheus-blackbox-exporter.service"
      "prometheus-node-exporter.service"
      "prometheus.service"
      "rspamd.service"
      "sshd.service"
      "systemd-journald.service"
      "systemd-logind.service"
      "systemd-networkd.service"
      "systemd-oomd.service"
      "systemd-timesyncd.service"
      "systemd-udevd.service"
    ];
  };

  slb.bgpData = {
    enable = true;
    name = "Lucas Bergman";
    email = "lucas@bergmans.us";
  };

  slb.ipAbuseReport = {
    enable = true;
    reportEmail = "lucas@bergmans.us";
  };

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "bergnet0" ];
  };

  slb.asnBlocking = {
    enable = true;
    asns = [
      "AS10429" # Vivo (Telefônica Brasil) (BR)
      "AS135377" # UCLOUD INFORMATION TECHNOLOGY (HK) LIMITED (HK)
      "AS18881" # TELEFÔNICA BRASIL LTDA (BR)
      "AS208137" # Feo Prest SRL (RO)
      "AS209605" # UAB Host Baltic (LT)
      "AS215929" # Data Campus Limited (HK)
      "AS25159" # PJSC MegaFon (RU)
      "AS29518" # Bredband2 AB (SE)
      "AS329278" # Truehost Cloud Limited (KE)
      "AS4134" # China Telecom Backbone (CN)
      "AS4766" # Korea Telecom (KR)
      "AS47890" # UNMANAGED LTD (GB)
      "AS48090" # TECHOFF SRV LIMITED (GB)
      "AS4837" # China Unicom Backbone (CN)
      "AS51852" # Private Layer INC (PA)
      "AS9318" # SK Broadband Co Ltd (KR)
      "AS9498" # Bharti Airtel Ltd (IN)
      "AS9808" # China Mobile Backbone (CN)
    ];
    setName = "brute-forcers";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
