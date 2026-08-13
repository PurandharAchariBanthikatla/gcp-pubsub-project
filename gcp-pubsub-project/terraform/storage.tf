# Bucket that Pub/Sub writes archived messages into (private)
resource "google_storage_bucket" "archive" {
  name                        = "${var.project_id}-${var.name_prefix}-archive"
  project                     = var.project_id
  location                    = var.archive_bucket_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true
  labels                      = var.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.apis]
}

# Let the Pub/Sub service agent write objects into the archive bucket
resource "google_storage_bucket_iam_member" "pubsub_sa_writer" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_project_service_identity.pubsub_sa.email}"
}

# Bucket that serves a small static status/dashboard site, fronted by the HTTP(S) LB
resource "google_storage_bucket" "site" {
  name                        = "${var.project_id}-${var.name_prefix}-site"
  project                     = var.project_id
  location                    = var.site_bucket_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true
  labels                      = var.labels

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  depends_on = [google_project_service.apis]
}

# Backend buckets served through an HTTP(S) Load Balancer must be publicly readable
resource "google_storage_bucket_iam_member" "site_public_read" {
  bucket = google_storage_bucket.site.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload the sample dashboard page
resource "google_storage_bucket_object" "index_html" {
  name         = "index.html"
  bucket       = google_storage_bucket.site.name
  source       = "${path.module}/../website/index.html"
  content_type = "text/html"
}
