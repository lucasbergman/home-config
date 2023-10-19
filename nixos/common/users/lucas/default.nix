{lib, ...}: {
  users.users.lucas = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = lib.pipe ./keys.json [
      builtins.readFile
      builtins.fromJSON
      builtins.attrValues
    ];
  };
}
