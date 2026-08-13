locals {
  required_apis = [
    "pubsub.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each                  = toset(local.required_apis)
  project                   = var.project_id
  service                   = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}
