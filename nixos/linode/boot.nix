{...}: {
  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "nodev";
      forceInstall = true;
      copyKernels = true;
      fsIdentifier = "label";
      extraConfig = ''
        serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
        terminal_input serial;
        terminal_output serial
      '';
    };
    loader.timeout = 10;
    kernelParams = ["console=ttyS0,19200n8"];
  };
}
