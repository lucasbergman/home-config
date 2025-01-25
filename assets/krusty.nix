{ lib, ... }:
{
  resource.hcloud_ssh_key.lucas_hedwig = {
    name = "lucas-hedwig";
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxQDnZ2MZ0Q+APiJ7u3MnJ+T23uNTkwyf5R6YJwzX49 lucas@hedwig";
  };

  resource.hcloud_ssh_key.lucas_snowball = {
    name = "lucas-snowball";
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2i5Qvu8pC44UPugMjyUx9bD44Dspovs2b5Kti2Qj13 lucas@snowball";
  };

  resource.hcloud_server.krusty = {
    name = "krusty";
    image = "ubuntu-24.04";
    server_type = "cpx31";
    location = "ash";
    ssh_keys = [
      (lib.tfRef "resource.hcloud_ssh_key.lucas_hedwig.id")
      (lib.tfRef "resource.hcloud_ssh_key.lucas_snowball.id")
    ];
    public_net = {
      ipv4_enabled = true;
      ipv6_enabled = true;
    };
  };
}
