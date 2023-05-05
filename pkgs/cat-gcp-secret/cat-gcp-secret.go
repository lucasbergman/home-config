package main

import (
	"context"
	"flag"
	"log"
	"os"

	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	secretmanagerpb "cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
)

func main() {
	envVarPtr := flag.String("e", "", "write output in .env file format using this as a variable name")
	flag.Parse()

	if len(flag.Args()) != 1 {
		flag.Usage()
		os.Exit(1)
	}
	version := flag.Arg(0)

	ctx := context.Background()
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		log.Fatalf("client creation failed: %s", err)
	}
	defer client.Close()

	req := &secretmanagerpb.AccessSecretVersionRequest{
		Name: version,
	}
	result, err := client.AccessSecretVersion(ctx, req)
	if err != nil {
		client.Close()
		log.Fatalf("failed to access secret [%s]: %s\n", version, err)
	}

	if *envVarPtr != "" {
		os.Stdout.WriteString(*envVarPtr)
		os.Stdout.WriteString("=")
	}

	os.Stdout.Write(result.Payload.Data)

	if *envVarPtr != "" {
		os.Stdout.WriteString("\n")
	}
}
