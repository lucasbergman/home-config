{...}: {
  imports = [
    ./monitoring.nix
    ./plex.nix
    ./unifi.nix
  ];

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
    networkNamespaceUnit = "netns@vpn.service";
  };
}
