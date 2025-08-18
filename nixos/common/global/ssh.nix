{ config, lib, ... }:
{
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkDefault config.slb.security.unsafeUnderConstruction;
    };
  };
}
