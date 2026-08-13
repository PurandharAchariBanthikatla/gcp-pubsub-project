# gcp-pubsub-project
GCP Pub/Sub end-to-end project using Terraform. Messages are published to a topic and fanned out to a pull subscription (worker), GCS subscription (auto-archive), and optional Cloud Run push subscription, with dead-letter handling. Includes a static GCS website via HTTPS Load Balancer + CDN and least-privilege IAM.
