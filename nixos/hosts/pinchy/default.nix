{
  lib,
  config,
  pkgs,
  mypkgs,
  ...
}:
{
  imports = [
    ../../common/global
    ../../common/users
    ../../common/users/hermes.nix
    ../../linode
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "pinchy";
    domain = "bergmans.us";
  };

  networking.nftables.enable = true;
  networking.firewall.enable = true;

  users.users.hermes.linger = true;

  slb.security.secrets."hermes-secrets" = {
    outPath = "/run/hermes-secrets.env";
    owner = "hermes";
    group = "hermes";
    # Values must be quoted because secrets like MATRIX_RECOVERY_KEY contain spaces,
    # which would otherwise break env file parsing (e.g. systemd/shell).
    template = pkgs.writeText "hermes-secrets.env" ''
      MATRIX_ACCESS_TOKEN="{{gcpSecret "projects/bergmans-services/secrets/hermes-matrix-access-token/versions/latest"}}"
      MATRIX_RECOVERY_KEY="{{gcpSecret "projects/bergmans-services/secrets/hermes-matrix-recovery-key/versions/latest"}}"
    '';
    restartUnits = [ "hermes-agent.service" ];
  };

  services.hermes-agent = {
    enable = true;
    createUser = false;
    user = "hermes";
    group = "hermes";
    stateDir = "/home/hermes";
    workingDirectory = "/home/hermes";
    addToSystemPackages = true;

    settings = {
      model = {
        default = "google/gemini-3-flash-preview";
        provider = "vertex";
      };
      terminal = {
        backend = "local";
        cwd = "/home/hermes";
      };
      platforms = {
        matrix = {
          enabled = true;
        };
      };
    };

    environment = {
      # Note: Generate a service account key and install it on the host
      VERTEX_PROJECT_ID = "bergmans-services";
      VERTEX_REGION = "global";
      VERTEX_CREDENTIALS_PATH = "/home/hermes/gcp_service_account.json";

      MATRIX_HOMESERVER = "https://matrix.bergman.house";
      MATRIX_E2EE_MODE = "required";
      MATRIX_USER_ID = "@hermes:bergman.house";
      MATRIX_ALLOWED_USERS = "@lucas:bergman.house";
    };
  };

  # The upstream services.hermes-agent module only reads environmentFiles during
  # NixOS system activation to merge into ~/.hermes/.env, but slb.security.secrets
  # populates /run/hermes-secrets.env at runtime via a systemd unit. Wiring
  # EnvironmentFile directly into the systemd service ensures the secrets are
  # available to the process on boot and restarts without activation timing issues.
  systemd.services.hermes-agent.serviceConfig.EnvironmentFile = [
    "/run/hermes-secrets.env"
  ];

  slb.backups.enable = false;
  slb.nebula.enable = true;

  services.resolved.settings = {
    Resolve.MulticastDNS = "no";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
