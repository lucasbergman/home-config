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

        One of the ways you can be of use is by making code changes for the users
        and sending them to GitHub as pull requests (PRs) for approval. You have a
        specific skill to make changes to the home-config repo.

        When changing or proposing edits to any repository or interacting with
        GitHub, use your GitHub App credentials:
        - Run `export GH_TOKEN=$(github-app-token)` to authenticate git and gh.
        - Author commits as:
          cogsworth[bot] <5643112+lucasbergman-cogsworth[bot]@users.noreply.github.com>
        - Push branches and create pull requests using `gh pr create --repo <repo-name>`.
      '';

      "skills/home-config/SKILL.md" = ''
        ---
        name: home-config
        description: "Guidelines and workflow for modifying home-config and opening GitHub pull requests"
        metadata:
          hermes:
            tags: [Git, GitHub, PullRequest, NixOS, home-config]
        ---

        # Home-Config Workflow

        This skill explains how Cogsworth makes changes to the
        `lucasbergman/home-config` repository and submits them as GitHub pull
        requests.

        ## Authentication
        Generate an installation token on demand:
        ```bash
        export GH_TOKEN=$(github-app-token)
        ```
        This token is valid for 1 hour and works with both `gh` and Git.

        ## Git Identity
        Set your commit author identity:
        ```bash
        git config user.name "cogsworth[bot]"
        git config user.email "5643112+lucasbergman-cogsworth[bot]@users.noreply.github.com"
        ```

        ## Creating a Pull Request
        1. Clone or update repository:
           ```bash
           git clone https://x-access-token:$GH_TOKEN@github.com/lucasbergman/home-config.git
           cd home-config
           ```
        2. Create a branch and make changes:
           ```bash
           git checkout -b <descriptive-branch-name>
           # make changes...
           git commit -am "Commit message"
           ```
        3. Push the branch:
           ```bash
           git push origin <descriptive-branch-name>
           ```
        4. Create the Pull Request:
           ```bash
           GH_TOKEN=$GH_TOKEN gh pr create \
             --repo lucasbergman/home-config \
             --head <descriptive-branch-name> \
             --base main \
             --title "Short title" \
             --body "Summary of changes"
           ```
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
