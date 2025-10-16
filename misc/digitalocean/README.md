On a NixOS Linux host, to generate an image for DigitalOcean, run:

```shell
$ nix build --file image.nix --no-link --print-out-paths
```

This grabs SSH public keys and does network setup through cloud-init, which is enough to
log into the VM as root.
