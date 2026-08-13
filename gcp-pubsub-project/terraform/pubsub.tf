# Main topic that publishers send events to
resource "google_pubsub_topic" "main" {
  name    = "${var.name_prefix}-events"
  project = var.project_id
  labels  = var.labels

  message_retention_duration = var.message_retention_duration

  depends_on = [google_project_service.apis]
}

# Dead-letter topic for messages that repeatedly fail processing
resource "google_pubsub_topic" "dead_letter" {
  name    = "${var.name_prefix}-events-dlq"
  project = var.project_id
  labels  = var.labels

  depends_on = [google_project_service.apis]
}

# Pull subscription — used by the sample subscriber.py worker
resource "google_pubsub_subscription" "pull" {
  name    = "${var.name_prefix}-events-pull-sub"
  project = var.project_id
  topic   = google_pubsub_topic.main.id
  labels  = var.labels

  ack_deadline_seconds      = var.ack_deadline_seconds
  message_retention_duration = var.message_retention_duration
  retain_acked_messages      = false

  expiration_policy {
    ttl = "" # never expires
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

# Optional push subscription — delivers HTTPS POSTs to e.g. a Cloud Run service
resource "google_pubsub_subscription" "push" {
  count   = var.push_endpoint != "" ? 1 : 0
  name    = "${var.name_prefix}-events-push-sub"
  project = var.project_id
  topic   = google_pubsub_topic.main.id
  labels  = var.labels

  ack_deadline_seconds = var.ack_deadline_seconds

  push_config {
    push_endpoint = var.push_endpoint
    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

# Cloud Storage subscription — Pub/Sub writes messages directly into the archive bucket
resource "google_pubsub_subscription" "gcs_archive" {
  name    = "${var.name_prefix}-events-gcs-sub"
  project = var.project_id
  topic   = google_pubsub_topic.main.id
  labels  = var.labels

  cloud_storage_config {
    bucket          = google_storage_bucket.archive.name
    filename_prefix = "events/"
    filename_suffix = ".json"

    max_duration = "300s"
    max_bytes    = 10000000 # 10 MB

    avro_config {
      write_metadata = true
    }
  }

  depends_on = [
    google_storage_bucket_iam_member.pubsub_sa_writer,
  ]
}

# Allow the Pub/Sub service agent to write into the archive bucket
resource "google_project_service_identity" "pubsub_sa" {
  project = var.project_id
  service = "pubsub.googleapis.com"
}
