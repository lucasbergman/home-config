{
  hosts = {
    spot = {
      ip = "10.7.1.1";
      name = "spot.priv.bergman.house";
      isNixos = true;
      isLighthouse = true;
    };
    hedwig = {
      ip = "10.7.1.2";
      name = "hedwig.priv.bergman.house";
      isNixos = true;
    };
    snowball = {
      ip = "10.7.1.3";
      name = "snowball.priv.bergman.house";
      isNixos = true;
    };
    cheddar = {
      ip = "10.7.1.4";
      name = "cheddar.priv.bergman.house";
      isNixos = true;
    };
    pinchy = {
      ip = "10.7.1.5";
      name = "pinchy.priv.bergman.house";
      isNixos = true;
    };
    lucas-pixel9 = {
      ip = "10.7.1.21";
      name = "lucas-pixel9.priv.bergman.house";
      isNixos = false;
    };
  };
}
