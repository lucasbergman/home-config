{ ... }:
let
  mkTimeMachineShare = user: {
    path = "/storage/backup/timemachine-${user}";
    browseable = "yes";
    writable = "yes";
    "read only" = "no";
    "valid users" = user;
    "force user" = user;
    "force group" = "users";
    "create mask" = "0600";
    "directory mask" = "0700";
    "fruit:aapl" = "yes";
    "fruit:time machine" = "yes";
    "fruit:time machine max size" = "500G";
  };
in
{
  services.samba = {
    enable = true;
    # Disable NetBIOS daemon; it cannot operate on point-to-point mesh networks
    # and is obsolete for modern macOS / SMB2+ clients.
    nmbd.enable = false;
    winbindd.enable = false;

    settings = {
      global = {
        workgroup = "CHATEAU";
        "server string" = "hedwig";
        "netbios name" = "hedwig";
        security = "user";

        # Restrict access strictly to Nebula mesh and localhost
        "hosts allow" = "10.7.1. 127.0.0.1";
        "hosts deny" = "0.0.0.0/0";

        # macOS / vfs_fruit optimizations
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "RackMac";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
      };

      "TimeMachine-Audrey" = mkTimeMachineShare "audrey";
      "TimeMachine-Resa" = mkTimeMachineShare "resa";
    };
  };
}
