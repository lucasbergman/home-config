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

  gitCredentialGithubApp = pkgs.writeShellScriptBin "git-credential-github-app" ''
    if [ "$1" = "get" ]; then
      echo "username=x-access-token"
      echo "password=$(${githubAppToken}/bin/github-app-token)"
    fi
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
      HASS_TOKEN="{{gcpSecret "projects/bergmans-services/secrets/hermes-home-assistant-token/versions/latest"}}"
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
    extraPlugins = [
      mypkgs.hermes-plugin-homeassistant
    ];
    extraPackages = with pkgs; [
      gh
      git
      gitCredentialGithubApp
      githubAppToken
      google-cloud-sdk
      jq
      nixfmt
      ripgrep
    ];

    settings = {
      plugins = {
        enabled = [ "homeassistant" ];
      };
      model = {
        default = "google/gemini-3.8-flash";
        provider = "vertex";
      };
      terminal = {
        backend = "local";
        cwd = "/home/hermes";
      };
      # Gemini Flash has a 1M-token window; the default 0.5 threshold wouldn't
      # compress until ~500K tokens. Compress early (~80K) to keep bills low.
      compression = {
        enabled = true;
        threshold = 0.08;
        target_ratio = 0.2;
        protect_last_n = 12;
      };
      # Disable post-turn background review (re-sends full context and cannot
      # patch NixOS-managed read-only skills).
      auxiliary = {
        background_review = {
          enabled = false;
        };
      };
      display = {
        interim_assistant_messages = false;
        tool_progress = "off";
      };
      # Prune bundled skills irrelevant to this headless NixOS server to trim
      # baseline system-prompt tokens on every API call.
      skills = {
        disabled = [
          "airtable"
          "apple-notes"
          "apple-reminders"
          "architecture-diagram"
          "arxiv"
          "ascii-art"
          "ascii-video"
          "audiocraft-audio-generation"
          "baoyu-infographic"
          "blogwatcher"
          "box"
          "claude-code"
          "claude-design"
          "codex"
          "comfyui"
          "competitor-news-monitor"
          "computer-use"
          "design-md"
          "document-to-action-items"
          "dogfood"
          "evaluating-llms-harness"
          "excalidraw"
          "findmy"
          "gif-search"
          "google-workspace"
          "heartmula"
          "hermes-agent-skill-authoring"
          "himalaya"
          "huggingface-hub"
          "humanizer"
          "imessage"
          "inspecting-hermes-desktop-dom"
          "jupyter-live-kernel"
          "llama-cpp"
          "llm-wiki"
          "manim-video"
          "meeting-action-items"
          "nano-pdf"
          "node-inspect-debugger"
          "notion"
          "obsidian"
          "ocr-and-documents"
          "opencode"
          "openhue"
          "p5js"
          "petdex"
          "polymarket"
          "popular-web-designs"
          "powerpoint"
          "pretext"
          "python-debugpy"
          "segment-anything-model"
          "serving-llms-vllm"
          "sketch"
          "songsee"
          "songwriting-and-ai-music"
          "spike"
          "touchdesigner-mcp"
          "weekly-review-planning"
          "weights-and-biases"
          "xurl"
          "yuanbao"
        ];
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

      CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE = "/home/hermes/gcp_service_account.json";
      CLOUDSDK_CORE_PROJECT = "bergmans-services";
      GOOGLE_APPLICATION_CREDENTIALS = "/home/hermes/gcp_service_account.json";

      MATRIX_HOMESERVER = "https://matrix.bergman.house";
      MATRIX_E2EE_MODE = "required";
      MATRIX_DM_AUTO_THREAD = "true";
      MATRIX_USER_ID = "@hermes:bergman.house";
      MATRIX_ALLOWED_USERS = lib.concatStringsSep "," [
        "@lucas:bergman.house"
        "@cristin:bergman.house"
        "@audrey:bergman.house"
      ];

      GITHUB_APP_KEY_PATH = "/run/hermes/github-app-key.pem";
      GITHUB_APP_CLIENT_ID = "Iv23liJABvsUqKAoz9vo";

      # Pre-configure git HTTPS auth (dynamic GitHub App token) and bot identity
      GIT_CONFIG_COUNT = "3";
      GIT_CONFIG_KEY_0 = "credential.https://github.com.helper";
      GIT_CONFIG_VALUE_0 = "${gitCredentialGithubApp}/bin/git-credential-github-app";
      GIT_CONFIG_KEY_1 = "user.name";
      GIT_CONFIG_VALUE_1 = "cogsworth[bot]";
      GIT_CONFIG_KEY_2 = "user.email";
      GIT_CONFIG_VALUE_2 = "5643112+lucasbergman-cogsworth[bot]@users.noreply.github.com";

      HASS_URL = "http://hedwig.priv.bergman.house:8123";
    };

    hermesHomeFiles = {
      "SOUL.md" = builtins.readFile ./hermes/SOUL.md;
      "skills/home-config/SKILL.md" = builtins.readFile ./hermes/skills/home-config/SKILL.md;
      "skills/mail-logs/SKILL.md" = builtins.readFile ./hermes/skills/mail-logs/SKILL.md;
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
