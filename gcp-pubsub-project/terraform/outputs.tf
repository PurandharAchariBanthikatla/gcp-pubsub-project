output "pubsub_topic" {
  description = "Main Pub/Sub topic name"
  value       = google_pubsub_topic.main.name
}

output "pubsub_dead_letter_topic" {
  value = google_pubsub_topic.dead_letter.name
}

output "pubsub_pull_subscription" {
  value = google_pubsub_subscription.pull.name
}

output "pubsub_gcs_subscription" {
  value = google_pubsub_subscription.gcs_archive.name
}

output "archive_bucket" {
  value = google_storage_bucket.archive.name
}

output "site_bucket" {
  value = google_storage_bucket.site.name
}

output "load_balancer_ip" {
  description = "Point your DNS A record (var.lb_domain) at this IP"
  value       = google_compute_global_address.lb_ip.address
}

output "load_balancer_url" {
  value = "https://${var.lb_domain}"
}

output "publisher_service_account" {
  value = google_service_account.publisher.email
}

output "subscriber_service_account" {
  value = google_service_account.subscriber.email
}

output "pubsub_push_invoker_service_account" {
  value = google_service_account.pubsub_invoker.email
}
