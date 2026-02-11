{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.slb.qemu = {
    enable = lib.mkEnableOption "Whether to enable qemu VMs";
  };

  config = lib.mkIf config.slb.qemu.enable {
    virtualisation.libvirtd = {
      enable = true;

      # Enable TPM emulation (for Windows 11)
      qemu = {
        swtpm.enable = true;
      };
    };

    # Enable USB redirection
    virtualisation.spiceUSBRedirection.enable = true;

    # Allow VM management
    users.groups.libvirtd.members = [ "lucas" ];
    users.groups.kvm.members = [ "lucas" ];
  };
}
