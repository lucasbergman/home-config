{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.slb = {
    isDesktop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this host is a GUI desktop environment";
    };

    enableDevelopment = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable development tools and packages";
    };
  };

  config = {
    # This module provides the options but doesn't implement any config yet
  };
}
