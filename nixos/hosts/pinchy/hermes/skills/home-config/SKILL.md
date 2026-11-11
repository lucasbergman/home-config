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
