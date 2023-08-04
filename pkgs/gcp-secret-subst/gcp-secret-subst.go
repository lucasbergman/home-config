package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path"
	"text/template"

	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	secretmanagerpb "cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
)

func main() {
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "usage: gcp-secret-subst TEMPLATEFILE\n")
		flag.PrintDefaults()
	}
	flag.Parse()

	if len(flag.Args()) != 1 {
		flag.Usage()
		os.Exit(1)
	}
	templateFile := flag.Arg(0)

	ctx := context.Background()
	secretsClient, err := secretmanager.NewClient(ctx)
	if err != nil {
		log.Fatalf("GCP secret manager client creation failed: %s", err)
	}
	defer secretsClient.Close()

	getSecret := func(version string) string {
		req := &secretmanagerpb.AccessSecretVersionRequest{
			Name: version,
		}
		result, err := secretsClient.AccessSecretVersion(ctx, req)
		if err != nil {
			secretsClient.Close()
			log.Fatalf("failed to access secret [%s]: %s", version, err)
		}
		return string(result.Payload.Data)
	}
	funcs := template.FuncMap{"gcpSecret": getSecret}

	tmpl, err := template.New(path.Base(templateFile)).Funcs(funcs).ParseFiles(templateFile)
	if err != nil {
		secretsClient.Close()
		log.Fatalf("failed to set up template: %s", err)
	}

	err = tmpl.Execute(os.Stdout, nil)
	if err != nil {
		secretsClient.Close()
		log.Fatalf("template execution failed: %s", err)
	}
}
