{...}: {
  imports = [
    ./home-vpn.nix
    ./monitoring.nix
    ./mullvad.nix
    ./plex.nix
    ./unifi.nix
  ];

  virtualisation.oci-containers.backend = "podman";

  users.users.idiotbox = {
    group = "idiotbox";
    uid = 2001;
    home = "/storage/media";
    isSystemUser = true;
  };

  users.groups.idiotbox = {
    gid = 2001;
  };

  slb.idiotbox = {
    enable = true;
    user = "idiotbox";
    group = "idiotbox";
    pod = "idiotbox";
    dependsOn = ["idiotbox-vpn"];
    mediaDirectory = "/storage/media";
  };
}
