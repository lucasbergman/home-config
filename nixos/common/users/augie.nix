{...}: {
  users.users.augie = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKp8gh09VlAfLM/IBM7z0xgwz6kD+XHw4H+vkx+VUc8 augie@home"
    ];
  };
}
