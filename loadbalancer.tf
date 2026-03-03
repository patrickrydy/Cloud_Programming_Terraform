# Cloud Armor WAF (Web Application Firewall / DDoS Protection)
# HINWEIS: Für diesen Prototyp temporär auskommentiert aufgrund restriktiver Free-Tier-Limits
# resource "google_compute_security_policy" "cloud_armor_policy" {
#   name = "stocksense-security-policy"
#   rule {
#     action   = "allow"
#     priority = "2147483647"
#     match {
#       versioned_expr = "SRC_IPS_V1"
#       config {
#         src_ip_ranges = ["*"]
#       }
#     }
#     description = "Default allow rule"
#   }
# }

# Backend Service zur Verknüpfung der Managed Instance Group mit dem Load Balancer
resource "google_compute_backend_service" "backend_service" {
  name                  = "stocksense-lb-backend"
  health_checks         = [google_compute_health_check.backend_hc.id]
  # Verknüpfung zur WAF (Deaktiviert)
  #security_policy       = google_compute_security_policy.cloud_armor_policy.id
  
  # Aktiviert das Cloud CDN für weltweites Caching
  enable_cdn            = true 

  backend {
    group = google_compute_region_instance_group_manager.backend_mig.instance_group
  }
}

# URL Map (Routet die Anfragen)
resource "google_compute_url_map" "default_url_map" {
  name            = "stocksense-url-map"
  default_service = google_compute_backend_service.backend_service.id
}

# HTTP Target Proxy - Leitet Anfragen an die URL Map weiter
resource "google_compute_target_http_proxy" "default_proxy" {
  name    = "stocksense-http-proxy"
  url_map = google_compute_url_map.default_url_map.id
}
# Global Forwarding Rule (Frontend des Load Balancers)
resource "google_compute_global_forwarding_rule" "default_rule" {
  name       = "stocksense-forwarding-rule"
  target     = google_compute_target_http_proxy.default_proxy.id
  port_range = "80" 
}