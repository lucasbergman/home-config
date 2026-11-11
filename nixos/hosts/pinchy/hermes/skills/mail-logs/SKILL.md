---
name: mail-logs
description: "Query Postfix and Rspamd mail logs on cheddar via Google Cloud Logging"
metadata:
    hermes:
        tags: [Mail, Postfix, Rspamd, Cheddar, GCP, Logging]
---

# Mail Logs Workflow

This skill explains how Cogsworth queries mail server logs for `cheddar.bergmans.us`
using Google Cloud Logging.

## Prerequisites

`gcloud` is installed and pre-configured with the service account credentials and
project (`bergmans-services`).

## Query Structure

All cheddar logs share a common host filter:

- **Host filter**:
  `resource.type="generic_node" AND resource.labels.node_id="cheddar.bergmans.us"`
- **Format**:
  `--format="table(timestamp.date('%Y-%m-%d %H:%M:%S'),jsonPayload.MESSAGE)"`
- **Limit**: Always pass `--limit=20` (or fewer) to keep output readable and prevent
  overwhelming the context.
- **Ordering**: Keep the default descending order (newest first). Do not use
  `--order=asc` without a recent timestamp filter, or GCP will scan backwards from the
  start of log retention.

## Postfix Queue IDs

Note that Postfix assigns a queue ID (10+ hex digits) as each transaction flows through
SMTP, milters, and queueing. Those queue IDs are normally preserved (and tagged "qid")
in the Rspamd milter. This can be used to trace a single message and analyze its entire
flow through the system.

## Examples

You can set shell helper variables for common base arguments:

```bash
BASE='resource.type="generic_node" AND resource.labels.node_id="cheddar.bergmans.us"'
FMT="table(timestamp.date('%Y-%m-%d %H:%M:%S'),jsonPayload.MESSAGE)"
```

### Recent Postfix delivery & connection logs:

```bash
gcloud logging read "$BASE AND jsonPayload._SYSTEMD_UNIT=\"postfix.service\"" \
  --limit=20 --format="$FMT"
```

### Recent Rspamd spam check & ARC signing logs:

```bash
gcloud logging read "$BASE AND jsonPayload._SYSTEMD_UNIT=\"rspamd.service\"" \
  --limit=20 --format="$FMT"
```

### Searching by email, queue ID, or Message-ID across services:

```bash
gcloud logging read "$BASE AND \"target@example.com\"" \
  --limit=20 \
  --format="table(timestamp.date('%Y-%m-%d %H:%M:%S'),jsonPayload._SYSTEMD_UNIT,jsonPayload.MESSAGE)"
```
