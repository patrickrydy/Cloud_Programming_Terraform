# Bereitstellung der logisch isolierten Virtual Private Cloud
# Automatisches Subnetting ist deaktiviert, um volle Kontrolle über den IP-Adressraum zu behalten
resource "google_compute_network" "vpc_network" {
  name                    = "stocksense-vpc"
  auto_create_subnetworks = false 
}

# Ein Subnetz in Frankfurt (europe-west3) erstellen
resource "google_compute_subnetwork" "subnet_frankfurt" {
  name          = "stocksense-subnet-fra"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Ingress-Firewall-Regel für externe Zugriffe
# Erlaubt HTTPS (Sicherheit), SSH (Wartung) und temporär HTTP (Port 80) für die Prototyp-Validierung
resource "google_compute_firewall" "allow_https_ssh" {
  name    = "stocksense-allow-https-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["443", "22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  
  target_tags = ["web-server"] 
}

# Allokation eines internen IP-Adressbereichs für das VPC-Peering
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

# Etablierung der privaten Service-Verbindung (VPC-Peering)
# Isoliert die Cloud SQL-Datenbank vollständig vom öffentlichen Internet (Secure-by-Design)
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Firewall-Regel speziell für Google Cloud Health Checks
# Erlaubt Anfragen des Load Balancers strikt nur aus den offiziellen GCP-IP-Bereichen
resource "google_compute_firewall" "allow_health_checks" {
  name    = "stocksense-allow-health-checks"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  
  target_tags   = ["web-server"]
}