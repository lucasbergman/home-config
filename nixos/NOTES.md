Notes on setting up a host

**Instance keys**: Every host gets a service account and a private key that it uses for
authenticating with Google Cloud. Generate the service account with Terraform, create a
new key, and drop that on the host:

```shell
$ gcloud iam service-accounts keys create KEY_FILE.json \
    --iam-account=SERVICE_ACCOUNT_EMAIL
$ install -o root -g root -m 0600 KEY_FILE.json /etc/gcp-instance-creds.json
```

**Nebula mesh network keys**: If the host uses the `bergnet` Nebula mesh network,
generate the host's key and certificate with `nebula-cert sign` and put them at
`/etc/nebula-bergnet-host.{crt,key}` on the host.
