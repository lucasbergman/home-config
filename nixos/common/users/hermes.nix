{ ... }: {
  users.users.hermes = {
    isNormalUser = true;
    description = "Hermes Agent user";
    group = "hermes";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrjs22msPKRAlQHnmlaAPCcSXd3FKgeR3MnM+Fta3P/"
    ];
  };

  users.groups.hermes = { };
}
