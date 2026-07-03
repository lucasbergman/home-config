{
  lib,
  buildFHSEnv,
  writeScript,
}:

buildFHSEnv {
  name = "hermes";

  targetPkgs =
    pkgs: with pkgs; [
      # Shell & basic utilities
      bash
      curl
      git
      openssh

      # Development tools for Python/Node build steps
      gcc
      gnumake
      binutils
      pkg-config
      zlib
      openssl
      libffi
      sqlite
      libxml2
      libxslt

      # Runtime deps for Hermes Agent
      python3
      nodejs
      uv
      ffmpeg
      ripgrep
      wl-clipboard
      xclip

      # Libraries for Python native modules & Playwright browsers
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libdrm
      libgbm
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      xorg.libX11
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXScrnSaver
      xorg.libXtst
      xorg.libxcb
      xorg.libxshmfence
    ];

  runScript = writeScript "hermes-wrapper" ''
    #!/usr/bin/env bash
    set -e

    export HERMES_HOME="''${HERMES_HOME:-$HOME/.hermes}"
    INSTALL_DIR="$HERMES_HOME/hermes-agent"

    if [ ! -f "$INSTALL_DIR/venv/bin/hermes" ]; then
      echo "Hermes Agent is not installed in $INSTALL_DIR."
      echo "Installing Hermes Agent now..."
      curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    fi

    # Run the installed hermes binary
    exec "$INSTALL_DIR/venv/bin/hermes" "$@"
  '';

  meta = {
    homepage = "https://hermes-agent.nousresearch.com/";
    description = "Autonomous AI agent framework with advanced tool-calling and persistent learning capabilities";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.lucasbergman ];
    mainProgram = "hermes";
  };
}
