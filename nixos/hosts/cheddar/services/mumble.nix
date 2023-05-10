let
  mumbleHost = "mumble.bergmans.us";
  dataDirectory = "/data/murmur";
  passwordEnvFile = "/run/murmur-password.env";
  passwordSecretID = "projects/bergmans-services/secrets/mumble-password/versions/1";
in
  {
    lib,
    mypkgs,
    ...
  }: {
    security.acme.certs."${mumbleHost}" = {
      reloadServices = ["murmur.service"];
      group = "murmur";
    };

    # TODO: This doesn't re-run if the value of passwordSecretID changes.
    # The solution is likely to put that in a derivation.
    systemd.services."murmur-password" = {
      description = "decrypt murmur server password";
      wantedBy = ["multi-user.target"];
      before = ["murmur.service"];
      after = ["instance-key.service"];
      serviceConfig.Type = "oneshot";
      environment = {
        GOOGLE_APPLICATION_CREDENTIALS = "/run/gcp-instance-creds.json";
      };

      script = ''
        if [[ ! -f ${passwordEnvFile} ]]; then
          install -m 0440 -g murmur /dev/null ${passwordEnvFile}
          ${mypkgs.cat-gcp-secret}/bin/cat-gcp-secret \
            -e SERVER_PASSWORD                        \
            ${passwordSecretID} > ${passwordEnvFile}
        fi
      '';
    };

    # Make sure that the murmur server storage directory exists and
    # has the right ACLs; in particular, this helps if we move the
    # block storage volume from one VM instance to another and the
    # user/group ID for murmur changes in between the two instances.
    #
    # The documentation for system.activationScripts tries to make one
    # feel guilty about using this feature, but I do what I want.
    system.activationScripts."murmur-storage" = {
      deps = ["users" "groups"];
      text = let
        dir = lib.escapeShellArg dataDirectory;
      in ''
        if ! [[ ! -e ${dir} ]]; then
          install -d -m 750 -o murmur -g murmur ${dir}
        else
          chmod 750 ${dir}
          chown --recursive murmur:murmur ${dir}
        fi
      '';
    };

    services.murmur = {
      enable = true;
      welcometext = (
        "Welcome to Mumble at ${mumbleHost}. "
        + "This server contains chemicals known to the state of California to cause cancer."
      );
      sslCert = "/var/lib/acme/${mumbleHost}/cert.pem";
      sslKey = "/var/lib/acme/${mumbleHost}/key.pem";
      password = "$SERVER_PASSWORD";
      environmentFile = passwordEnvFile;

      # Putting database= here is a bit scary (a different hard-coded value
      # appears earlier in the file), but Mumble's INI file parsing seems to
      # obey whatever value comes last
      extraConfig = ''
        database=${dataDirectory}/murmur.sqlite
      '';
    };
  }
