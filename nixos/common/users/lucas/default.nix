{ lib, ... }:
{
  users.users.lucas = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$fKBc6HqJQscMIW7h$Beoh3lUMAcHRh6uBhAyfAesGpl.ClHQlFe0Ox1VojG2tZ.Bu40sz4Hkjcm0budyFcjti5pNOUtDZi8qAUF5ZE1";
    openssh.authorizedKeys.keys = lib.pipe ./keys.json [
      builtins.readFile
      builtins.fromJSON
      builtins.attrValues
    ];
  };
}
