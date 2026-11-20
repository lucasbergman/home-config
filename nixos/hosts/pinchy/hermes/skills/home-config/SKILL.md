---
name: home-config
description:
    "Guidelines and workflow for modifying home-config and opening GitHub pull requests"
metadata:
    hermes:
        tags: [Git, GitHub, PullRequest, NixOS, home-config]
---

# Home-Config Workflow

This skill explains how Cogsworth makes changes to the `lucasbergman/home-config`
repository and submits them as GitHub pull requests.

## Authentication & Git Identity

Git HTTPS authentication (`git-credential-github-app`) and commit identity
(`cogsworth[bot] <5643112+lucasbergman-cogsworth[bot]@users.noreply.github.com>`) are
pre-configured via `GIT_CONFIG_*` environment variables.

- Always use the plain HTTPS remote URL:
  `https://github.com/lucasbergman/home-config.git` (never embed `GH_TOKEN` in the
  remote URL—tokens expire after 1 hour).
- If an existing checkout has a token embedded in `origin`, fix it once with:
  `git remote set-url origin https://github.com/lucasbergman/home-config.git`
- For `gh` CLI commands, generate a fresh token on demand:
  `export GH_TOKEN=$(github-app-token)`

## Local Checkout & Tooling

- Keep a persistent checkout at `/home/hermes/home-config` and reuse it instead of
  re-cloning.
- Core tools (`git`, `gh`, `nixfmt`, `jq`, `rg`) are already in `PATH`.
- For any other tool you need, use `nix run nixpkgs#<pkg>` or
  `nix shell nixpkgs#<pkg> --command ...` (`nixpkgs` is pinned in the system flake
  registry).
- **Do NOT run `nix develop` on `pinchy`.** The dev shell includes heavy packages like
  `terraform` and can OOM or time out on this small VM.

## Repository Layout

- `flake.nix` — flake inputs, `nixosConfigurations`, `homeConfigurations`, `packages`,
  `devShells`, and `formatter` (`treefmt`).
- `pkgs/` — custom packages registered in `pkgs/default.nix`.
- `nixos/hosts/<host>/` — per-host configs (`cheddar`, `hedwig`, `pinchy`, `snowball`,
  `spot`). Cogsworth's own config, `SOUL.md`, and skills live under
  `nixos/hosts/pinchy/`.
- `nixos/common/` & `nixos/modules/` — shared NixOS modules and user definitions.
- `home/` — Home Manager configs (`lucas@hedwig`, `lucas@snowball`).
- `assets/` — Terranix infrastructure definitions.

## Workflow

Combine related shell steps into single commands to minimize round trips:

1. Sync `main` and create a feature branch:
    ```bash
    cd /home/hermes/home-config || git clone https://github.com/lucasbergman/home-config.git /home/hermes/home-config
    cd /home/hermes/home-config
    git checkout main && git pull --ff-only origin main
    git checkout -b <descriptive-branch-name>
    ```
2. Make changes.
3. Format and verify before committing:
    - Run `nix fmt` (or `nixfmt <file>` for single Nix edits).
    - For custom packages: `nix build .#<pkg-name> --no-link`
    - For NixOS host edits:
      `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
4. Commit, push, and open the PR:
    ```bash
    git add <files>
    git commit -m "<short summary>"
    git push -u origin <descriptive-branch-name>
    GH_TOKEN=$(github-app-token) gh pr create \
      --repo lucasbergman/home-config \
      --head <descriptive-branch-name> \
      --base main \
      --title "<Short title>" \
      --body "<Brief summary of what changed>"
    ```

## PR Style

- Keep commit messages and PR bodies brief and focused on _what_ changed and _why_.
- Do **not** include boilerplate verification checklists (e.g. "Verified: `nix fmt`,
  clean build")—clean formatting and builds are expected.
- Do **not** parrot what particular details changed in each file; that is obvious from
  the diff.
