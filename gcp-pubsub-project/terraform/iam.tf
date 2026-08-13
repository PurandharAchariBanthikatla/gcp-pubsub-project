# --- Service accounts, least-privilege per role -----------------------------

resource "google_service_account" "publisher" {
  account_id   = "${var.name_prefix}-publisher"
  display_name = "Pub/Sub Publisher (app/publisher.py)"
  project      = var.project_id
}

resource "google_service_account" "subscriber" {
  account_id   = "${var.name_prefix}-subscriber"
  display_name = "Pub/Sub Subscriber (app/subscriber.py)"
  project      = var.project_id
}

# Identity used by Pub/Sub to sign OIDC tokens when calling the push endpoint
resource "google_service_account" "pubsub_invoker" {
  account_id   = "${var.name_prefix}-push-invoker"
  display_name = "Pub/Sub Push Invoker"
  project      = var.project_id
}

# --- Pub/Sub role bindings, scoped to specific resources, not project-wide --

resource "google_pubsub_topic_iam_member" "publisher_can_publish" {
  project = var.project_id
  topic   = google_pubsub_topic.main.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.publisher.email}"
}

resource "google_pubsub_subscription_iam_member" "subscriber_can_pull" {
  project      = var.project_id
  subscription = google_pubsub_subscription.pull.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.subscriber.email}"
}

# If a push endpoint is a Cloud Run / Cloud Functions service, grant the
# invoker identity permission to invoke it. Uncomment and point at your
# service once it exists — left out here since the service is external
# to this module.
#
# resource "google_cloud_run_v2_service_iam_member" "pubsub_invoke" {
#   name     = "your-cloud-run-service-name"
#   location = var.region
#   project  = var.project_id
#   role     = "roles/run.invoker"
#   member   = "serviceAccount:${google_service_account.pubsub_invoker.email}"
# }

# --- Storage role bindings ----------------------------------------------------

# Subscriber worker also needs to read archived events back from the bucket
resource "google_storage_bucket_iam_member" "subscriber_reads_archive" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.subscriber.email}"
}
