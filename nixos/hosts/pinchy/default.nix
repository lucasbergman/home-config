{
  lib,
  config,
  pkgs,
  mypkgs,
  ...
}:
let
  githubAppToken =
    pkgs.writers.writePython3Bin "github-app-token"
      {
        libraries = with pkgs.python3Packages; [
          pyjwt
          cryptography
          requests
        ];
      }
      ''
        import os
        import sys
        import time
        import jwt
        import requests

        key_path = os.environ.get(
            "GITHUB_APP_KEY_PATH",
            "/run/hermes/github-app-key.pem",
        )
        client_id = os.environ.get(
            "GITHUB_APP_CLIENT_ID",
            "Iv23liJABvsUqKAoz9vo",
        )

        if not os.path.exists(key_path):
            sys.exit(f"Error: Private key not found at {key_path}")

        with open(key_path, "r") as f:
            private_key = f.read()

        now = int(time.time())
        payload = {
            "iat": now - 60,
            "exp": now + 600,
            "iss": client_id,
        }
        jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

        headers = {
            "Authorization": f"Bearer {jwt_token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "Cogsworth-Bot",
        }

        inst_url = "https://api.github.com/app/installations"
        inst_res = requests.get(inst_url, headers=headers)
        if inst_res.status_code != 200:
            sys.exit(f"Failed to fetch installations: {inst_res.text}")

        installations = inst_res.json()
        if not installations:
            sys.exit(
                "Error: GitHub App is not installed on any accounts or repos. "
                "Go to GitHub App settings -> 'Install App' and install it."
            )

        installation_id = installations[0]["id"]
        token_url = (
            f"https://api.github.com/app/installations/{installation_id}"
            "/access_tokens"
        )
        token_res = requests.post(token_url, headers=headers)
        if token_res.status_code != 201:
            sys.exit(f"Failed to generate access token: {token_res.text}")

        print(token_res.json()["token"])
      '';
in
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

  slb.security.secrets."hermes-github-app-key" = {
    outPath = "/run/hermes/github-app-key.pem";
    owner = "hermes";
    group = "hermes";
    secretPath = "projects/bergmans-services/secrets/hermes-github-app-private-key/versions/latest";
    restartUnits = [ "hermes-agent.service" ];
  };

  environment.systemPackages = with pkgs; [
    githubAppToken
    git
    gh
  ];

  services.hermes-agent = {
    enable = true;
    createUser = false;
    user = "hermes";
    group = "hermes";
    stateDir = "/home/hermes";
    workingDirectory = "/home/hermes";
    addToSystemPackages = true;
    extraPackages = with pkgs; [
      gh
      git
      githubAppToken
      ripgrep
    ];

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
      MATRIX_ALLOWED_USERS = lib.concatStringsSep "," [
        "@lucas:bergman.house"
        "@cristin:bergman.house"
        "@audrey:bergman.house"
      ];

      GITHUB_APP_KEY_PATH = "/run/hermes/github-app-key.pem";
      GITHUB_APP_CLIENT_ID = "Iv23liJABvsUqKAoz9vo";
    };

    hermesHomeFiles = {
      "SOUL.md" = builtins.readFile ./hermes/SOUL.md;
      "skills/home-config/SKILL.md" = builtins.readFile ./hermes/skills/home-config/SKILL.md;
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
