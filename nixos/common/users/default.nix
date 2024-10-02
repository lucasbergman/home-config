{ ... }:
{
  imports = [ ./lucas ];

  security.sudo.wheelNeedsPassword = false;
  users = {
    # Users can only be made declaratively
    mutableUsers = false;
  };
}
