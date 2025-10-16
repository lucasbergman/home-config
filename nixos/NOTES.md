Notes on setting up a host

1. **Instance keys**: Every host gets a role account and a private key that it uses for
   authenticating with Google Cloud. For now, you have to generate one with Terraform,
   get the SSH host public key from the new host, encrypt the instance key with sops,
   then check that into Git. That's a bit overwrought, and we may as well just stick
   them on the host by hand.
2. **WireGuard keys**: If the host needs one or more WireGuard keys, generate those and
   stick them on the host by hand. We'll clean that up soon.
