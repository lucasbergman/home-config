#!/bin/sh
set -e

usage() {
    echo "encrypt-gcp-key HOST KEYFILE" >&2
    exit 44
}

[ -z "$1" ] && usage
HOST="$1"
shift
[ -z "$1" ] && usage
KEYFILE="$1"
shift

KEY="$(ssh-keyscan -t ssh-ed25519 "$HOST" 2>/dev/null | ssh-to-age)"
exec sops --encrypt \
    --age "$KEY" \
    --input-type json \
    --encrypted-regex '^private' \
    "$KEYFILE"
