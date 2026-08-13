variable "project_id" {
  description = "GCP project ID to deploy into"
  type        = string
}

variable "region" {
  description = "Default region for regional resources"
  type        = string
  default     = "asia-south1"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names, must be globally-unique-friendly"
  type        = string
  default     = "pubsub-e2e"
}

variable "archive_bucket_location" {
  description = "Location for the Pub/Sub message archive bucket"
  type        = string
  default     = "ASIA"
}

variable "site_bucket_location" {
  description = "Location for the static website bucket served by the Load Balancer"
  type        = string
  default     = "ASIA"
}

variable "push_endpoint" {
  description = "HTTPS endpoint for the Pub/Sub push subscription (e.g. a Cloud Run URL). Leave blank to skip creating the push subscription."
  type        = string
  default     = ""
}

variable "message_retention_duration" {
  description = "How long Pub/Sub retains unacked messages"
  type        = string
  default     = "604800s" # 7 days
}

variable "ack_deadline_seconds" {
  description = "Subscription acknowledgement deadline"
  type        = number
  default     = 20
}

variable "max_delivery_attempts" {
  description = "Attempts before a message is sent to the dead-letter topic"
  type        = number
  default     = 5
}

variable "lb_domain" {
  description = "Domain name pointed at the load balancer's static IP, used for the managed SSL cert (e.g. status.example.com). Required if using the HTTPS proxy as-is."
  type        = string
  default     = "example.com"
}

variable "enable_cdn" {
  description = "Enable Cloud CDN on the load balancer's backend bucket"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Common labels applied to resources that support them"
  type        = map(string)
  default = {
    project = "pubsub-e2e"
    managed = "terraform"
  }
}
