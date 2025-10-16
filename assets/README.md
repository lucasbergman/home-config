# About This

This is a Terraform plan for managing assets in public cloud services. The Terraform
configuration is written in the Nix language and translated to JSON by
[Terranix](https://terranix.org/).

Minimum survival commands:

```shell
$ nix run .#terraform-plan
$ nix run .#terraform-apply
```

## First-time State Storage Setup

Terraform state is stored in a Google Cloud Storage bucket. Minimum survival commands:

```shell
# Check that our Terraform state storage bucket exists already:
$ gsutil ls -p bergmans-services
gs://bergmans-services-home/

# If it doesn't exist, create it:
$ gsutil mb -p bergmans-services -b on --pap enforced gs://bergmans-services-home

# The -b and --pap options nail down bucket security; the first turns on
# "uniform bucket access" and the second turns on "public access prevention" so
# it can't accidentally be exposed over the internet.
```

## Setting Up Secrets

Secrets get stored manually to keep them from being stored in Terraform state or version
control, even encrypted. Minimum survival commands:

```shell
# Check whether we have our Restic backup password stored:
$ gcloud secrets versions list restic-password-cheddar
NAME  STATE    CREATED              DESTROYED
1     enabled  2023-05-05T19:58:24  -

# If not, we have to store it for the first time:
$ echo -n PASSWORD_HERE | \
    gcloud secrets versions add restic-password-cheddar --data-file=/dev/stdin
```
