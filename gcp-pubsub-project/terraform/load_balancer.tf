# Reserve a global static IP for the load balancer
resource "google_compute_global_address" "lb_ip" {
  name    = "${var.name_prefix}-lb-ip"
  project = var.project_id
}

# Backend bucket: connects the LB to the GCS static site bucket
resource "google_compute_backend_bucket" "site" {
  name        = "${var.name_prefix}-site-backend"
  project     = var.project_id
  bucket_name = google_storage_bucket.site.name
  enable_cdn  = var.enable_cdn

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
  }
}

# URL map: all paths route to the backend bucket
resource "google_compute_url_map" "site" {
  name            = "${var.name_prefix}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_bucket.site.id
}

# Google-managed SSL certificate. Replace the domain before applying,
# or delete this + the HTTPS proxy/forwarding rule to run HTTP-only for testing.
resource "google_compute_managed_ssl_certificate" "site" {
  name    = "${var.name_prefix}-cert"
  project = var.project_id

  managed {
    domains = [var.lb_domain]
  }
}

resource "google_compute_target_https_proxy" "site" {
  name             = "${var.name_prefix}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.site.id
  ssl_certificates = [google_compute_managed_ssl_certificate.site.id]
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.name_prefix}-https-fwd"
  project               = var.project_id
  ip_address            = google_compute_global_address.lb_ip.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.site.id
  load_balancing_scheme = "EXTERNAL"
}

# Redirect plain HTTP to HTTPS
resource "google_compute_url_map" "http_redirect" {
  name    = "${var.name_prefix}-http-redirect"
  project = var.project_id

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "site" {
  name    = "${var.name_prefix}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.name_prefix}-http-fwd"
  project               = var.project_id
  ip_address            = google_compute_global_address.lb_ip.address
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.site.id
  load_balancing_scheme = "EXTERNAL"
}
