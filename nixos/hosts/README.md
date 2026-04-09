This directory contains a NixOS configurations, one directory per host:

- cheddar: server on Akamai (formerly Linode)
- hedwig: server in the house
- snowball: desktop in the house
- spot: small server on Akamai (formerly Linode), Nebula lighthouse

## Notes on setting up a new host

Generate and install a key for the GCP service account:

```shell
$ gcloud iam service-accounts keys create NEWHOST-key.json \
    --iam-account=instance-NEWHOST@bergmans-services.iam.gserviceaccount.com
$ scp NEWHOST-key.json NEWHOST.bergmans.us:

# on the new host
$ sudo install -o 0 -g 0 -m 400 NEWHOST-key.json /etc/gcp-instance-creds.json
$ sudo systemctl restart instance-key.service
$ sudo systemctl restart acme-order-renew-NEWHOST.bergmans.us.service
```

Generate, sign, and install a new Nebula key and certificate:

```shell
$ nebula-cert sign -name NEWHOST.priv.bergman.house -ip "10.7.1.NEWADDR/24"
$ scp NEWHOST.priv.bergman.house.{crt,key} NEWHOST.bergmans.us:

# on the new host
$ sudo install -m 440 -o 0 -g nebula-bergnet NEWHOST.priv.bergman.house.key /etc/nebula-bergnet-host.key
$ sudo install -m 444 -o 0 -g nebula-bergnet NEWHOST.priv.bergman.house.crt /etc/nebula-bergnet-host.crt
$ sudo systemctl restart nebula@bergnet.service
```
