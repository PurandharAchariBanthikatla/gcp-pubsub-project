terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }

  # Uncomment and configure for remote state (recommended for real projects)
  # backend "gcs" {
  #   bucket = "YOUR_TF_STATE_BUCKET"
  #   prefix = "pubsub-e2e/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
