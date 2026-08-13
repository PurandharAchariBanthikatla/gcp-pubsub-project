# GCP Pub/Sub End-to-End Project

A complete, deployable Terraform project demonstrating Pub/Sub combined with
Cloud Storage, IAM, and an external HTTP(S) Load Balancer, plus sample
publisher/subscriber apps.

## Architecture

```
                     ┌─────────────────────┐
   publisher.py ───▶ │  Pub/Sub Topic       │
  (SA: publisher)     │  pubsub-e2e-events   │
                     └─────┬─────┬──────────┘
                           │     │
              ┌────────────┘     └───────────────┐
              ▼                                   ▼
   ┌─────────────────────┐          ┌─────────────────────────┐
   │ Pull subscription     │          │ Cloud Storage subscription│
   │ -> subscriber.py       │          │ -> archive bucket (GCS)   │
   │ (SA: subscriber)       │          └─────────────────────────┘
   └─────────────────────┘
              │ (on repeated failure)
              ▼
   ┌─────────────────────┐
   │ Dead-letter topic      │
   └─────────────────────┘

   Optional: Push subscription -> Cloud Run push_receiver.py
             (OIDC-signed by SA: pubsub-push-invoker)

   ┌─────────────────────────────────────────────┐
   │ Internet ──▶ Global HTTP(S) Load Balancer      │
   │              (Cloud CDN) ──▶ Backend Bucket     │
   │                              ──▶ site bucket (GCS)│
   │              serves website/index.html          │
   └─────────────────────────────────────────────┘
```

## What Terraform creates

**Pub/Sub**
- `pubsub-e2e-events` topic
- `pubsub-e2e-events-dlq` dead-letter topic
- `pubsub-e2e-events-pull-sub` pull subscription (used by `subscriber.py`)
- `pubsub-e2e-events-push-sub` push subscription (optional, only if `push_endpoint` is set)
- `pubsub-e2e-events-gcs-sub` Cloud Storage subscription that archives every message straight into GCS as JSON

**Cloud Storage**
- `<project>-pubsub-e2e-archive` — private bucket Pub/Sub writes archived messages into, versioned, 90-day lifecycle deletion
- `<project>-pubsub-e2e-site` — public, static-website-configured bucket serving `website/index.html`

**IAM**
- `pubsub-e2e-publisher` SA — `roles/pubsub.publisher` on the topic only
- `pubsub-e2e-subscriber` SA — `roles/pubsub.subscriber` on the pull subscription + `roles/storage.objectViewer` on the archive bucket
- `pubsub-e2e-push-invoker` SA — used by Pub/Sub to sign OIDC tokens for the push subscription
- Pub/Sub's own service agent is granted `roles/storage.objectAdmin` scoped to just the archive bucket (not project-wide)

**Load Balancer**
- Global static IP
- Backend bucket pointing at the site bucket, with Cloud CDN enabled
- URL map, Google-managed SSL cert, HTTPS proxy + forwarding rule
- HTTP proxy + forwarding rule that redirects to HTTPS

## Prerequisites

- A GCP project with billing enabled
- `gcloud` CLI authenticated (`gcloud auth application-default login`)
- Terraform >= 1.5
- A domain name you control, for the Load Balancer's managed SSL cert (or skip HTTPS — see below)

## Deploy

```bash
cd gcp-pubsub-e2e
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit terraform.tfvars: set project_id and lb_domain at minimum

./deploy.sh plan
./deploy.sh apply
```

After `apply`, Terraform prints `load_balancer_ip`. Point an A record for
`lb_domain` at that IP. The Google-managed certificate takes 15–60 minutes
to provision after DNS propagates — until then HTTPS will fail, but the
site bucket and Pub/Sub resources are already live.

**Skipping HTTPS for a quick test:** if you don't have a domain handy,
comment out the `google_compute_managed_ssl_certificate`,
`google_compute_target_https_proxy`, and `google_compute_global_forwarding_rule.https`
blocks in `terraform/load_balancer.tf`, and just use the HTTP forwarding
rule's IP directly in a browser.

## Try the Pub/Sub pipeline

```bash
cd app
pip install -r requirements.txt

# publish some sample events (uses your gcloud application-default credentials,
# or point GOOGLE_APPLICATION_CREDENTIALS at a key for the publisher SA)
python publisher.py --project YOUR_PROJECT_ID --count 5

# in another terminal, pull them
python subscriber.py --project YOUR_PROJECT_ID
```

Check the archive bucket for the same messages written as JSON:

```bash
gsutil ls gs://YOUR_PROJECT_ID-pubsub-e2e-archive/events/
```

## Optional: push subscription via Cloud Run

1. Deploy `app/push_receiver.py`:
   ```bash
   gcloud run deploy pubsub-e2e-push-receiver \
     --source app/ \
     --region asia-south1 \
     --no-allow-unauthenticated
   ```
2. Uncomment the `google_cloud_run_v2_service_iam_member.pubsub_invoke` block
   in `terraform/iam.tf` and set the service name.
3. Set `push_endpoint` in `terraform.tfvars` to the Cloud Run URL + `/pubsub/push`.
4. Re-run `./deploy.sh apply` — this creates the push subscription and wires
   up the OIDC-authenticated invoker.

## Cleanup

```bash
./deploy.sh destroy
```

Note: both buckets are created with `force_destroy = true` so Terraform can
delete them even if they still contain objects. Remove that if you want a
safety net against accidental data loss in production.

## Cost notes

Everything here uses low-volume, mostly free-tier-eligible resources except
the Load Balancer, which has a small fixed hourly charge (forwarding rules)
plus data-processing charges — it's the most expensive piece of this stack
if left running. Cloud CDN reduces backend egress but egress from the LB
itself is still billed. Destroy the stack (`./deploy.sh destroy`) when not
in use to avoid ongoing charges.
