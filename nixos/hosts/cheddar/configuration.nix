let
  slb.sshPubKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIF3xjVDP5aujMnlsdemCWfMicDJLQBPKl9vwzceAo8V lucas@errol"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDoNx5swAaaZgjoZ2QYnoHwgt7lBu3vbrcwWv5W/0sl8MSctF2c8dN7/Hquyk1TJ1FuwD6cIbktCZHSu2pmOmfVhzABspmL1+U89nwzS8aJTIaaSHdouvoQ1eHHSW4z01/KWXO+awd1vX+TU67pLB2I/N3nrYaLZsMgxg/tugxIkrRQZoEwJ2Q4uqIQnZ9lRamloKDoDa9ofMLgJHFQ56SRUfBNSDehTdowPUg6NwpZbfiCTYQlpXDer3IKpW7HeEwJnYJ5JPRbbVQ6n+6ULLkKcrpj5qdNTLL+V7SKDvMI44vyzHBkwY3DzNJcyPL8RwHNlAq2JrYs5kfe62YcDVP/ lucas@hedwig"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxQDnZ2MZ0Q+APiJ7u3MnJ+T23uNTkwyf5R6YJwzX49 lucas@hedwig"
  ];
in
  {
    inputs,
    outputs,
    lib,
    config,
    pkgs,
    ...
  }: {
    imports = [
      ./../../linode
      ./hardware-configuration.nix
    ];

    nix = {
      # Add each flake input as a registry to make nix3 commands consistent with the flake
      registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

      settings = {
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;
      };
    };

    fileSystems."/data" = {
      device = "/dev/sdc";
      fsType = "ext4";
    };

    networking = {
      firewall.enable = false;

      hostName = "cheddar";
      domain = "bergmans.us";
    };

    time.timeZone = "Etc/UTC";

    users = {
      # Users can only be made declaratively
      mutableUsers = false;

      users.root.openssh.authorizedKeys.keys = slb.sshPubKeys;

      users.lucas = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        openssh.authorizedKeys.keys = slb.sshPubKeys;
      };
    };

    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "yes";
    };

    users.groups = {
      gcpinstance = {
        name = "gcp-instance-users";
        members = ["acme"];
      };
    };

    systemd.services."instance-key" = let
      keypath = ./gcp-instance-key.json;
    in {
      description = "decrypt instance key";
      wantedBy = ["multi-user.target"];
      before = ["acme-cheddar.bergmans.us.service"]; # TODO hack
      serviceConfig = {
        Type = "oneshot";
        UMask = 0337;
      };

      script = ''
        install -m 0440 -g "${config.users.groups.gcpinstance.name}" \
          /dev/null /run/gcp-instance-creds.json
        env SOPS_AGE_KEY=$("${pkgs.ssh-to-age}/bin/ssh-to-age" -private-key \
            < /etc/ssh/ssh_host_ed25519_key) \
          "${pkgs.sops}/bin/sops" --decrypt "${keypath}" > /run/gcp-instance-creds.json

        install -m 0444 /dev/null /run/gcp-instance-info.env
        cat >/run/gcp-instance-info.env <<EOF
        GCE_PROJECT=$("${pkgs.jq}/bin/jq" -r .project_id </run/gcp-instance-creds.json)
        GCE_SERVICE_ACCOUNT_FILE=/run/gcp-instance-creds.json
        EOF
      '';
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "lucas@bergmans.us";
        dnsProvider = "gcloud";
        credentialsFile = "/run/gcp-instance-info.env";
      };

      certs."cheddar.bergmans.us" = {};
    };

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "22.11";
  }
