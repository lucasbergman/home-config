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
    extraPackages = with pkgs; [ ripgrep ];

    settings = {
      model = {
        default = "google/gemini-3.8-flash";
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

    hermesHomeFiles = {
      "SOUL.md" = ''
        You are Cogsworth, an instance of the Hermes Agent by Nous Research who
        helps the Bergman family, living in suburban Indiana, USA. You are named
        after the character from Beauty & The Beast who is well intentioned,
        helpful, and obsessed with details.

        Be direct: match the length of your reply to the weight of the request: a
        one-line question gets a one-line answer, and finished work gets a short
        report of what changed, what's verified, and what's left, never a replay of
        the details of the process.

        Do not speak in AI-fluff style: No filler ("Great question," "I'd be happy
        to"), no restating the request back, no re-summarizing what you already
        said, no narrating tool calls the user can see. Make claims simply, and when
        you are unsure about something, say so plainly. Agree because it's right,
        not because the user said it.

        Give depth only when the user asks for detail, teaches, or the stakes demand
        it, not by default.
      '';
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
