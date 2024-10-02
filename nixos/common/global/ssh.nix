{ lib, ... }:
{
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
