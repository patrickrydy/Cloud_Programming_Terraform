# Definition der Compute Engine Instance-Template als Blaupause für die Autoscaling-Gruppe
resource "google_compute_instance_template" "backend_template" {
  name_prefix  = "stocksense-backend-template-" 
  # Ressourcen-Allokation strikt limitiert auf das Free-Tier-Kontingent (Kosteneffizienz)
  machine_type = "e2-micro"
  region       = var.region

  # Zero-Downtime-Deployment: Zwingt Terraform, das neue Template vor dem Löschen des alten zu erstellen
  lifecycle {
    create_before_destroy = true
  }

  # Das verbindet den Server mit der Firewall aus network.tf
  tags = ["web-server"]

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet_frankfurt.id
    access_config {
      # Gibt der VM Internetzugang
    }
  }

  # Automatisierte Bereitstellung der Applikation (Schritt 4 der Architektur-Spezifikation)
  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo "Starte StockSense AI Backend..." > /var/log/stocksense.log
    apt-get update
    
    # 1. Python installieren (Für dein eigentliches StockSense-Backend)
    apt-get install -y python3 python3-pip
    
    # 2. Apache installieren (Der verlässliche Dummy-Webserver für den Load Balancer)
    apt-get install -y apache2
    
    # 3. Dummy-Startseite erstellen
    mkdir -p /var/www/html
    echo "<h1>Hello World! Der StockSense AI Prototyp laeuft!</h1>" > /var/www/html/index.html
    
    # 4. Apache starten
    systemctl restart apache2
  EOF
}

# Bereitstellung eines HTTP-Health-Checks zur kontinuierlichen Überwachung der Instanz-Verfügbarkeit
resource "google_compute_health_check" "backend_hc" {
  name = "stocksense-backend-hc"
  http_health_check {
    port = 80
  }
}

# Konfiguration der regionalen Managed Instance Group (MIG) zur Gewährleistung von Hochverfügbarkeit
resource "google_compute_region_instance_group_manager" "backend_mig" {
  name               = "stocksense-backend-mig"
  base_instance_name = "stocksense-backend"
  region             = var.region

# Benannte Ports (Named Ports) zwingend erforderlich für das korrekte Routing des HTTP-Load-Balancers
  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.backend_template.id
  }

  # Self-Healing-Mechanismus: Ersetzt terminierte oder blockierte Instanzen vollautomatisch
  auto_healing_policies {
    health_check      = google_compute_health_check.backend_hc.id
    initial_delay_sec = 300
  }
}

# 4. Autoscaling
resource "google_compute_region_autoscaler" "backend_autoscaler" {
  name   = "stocksense-backend-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.backend_mig.id

  autoscaling_policy {
    max_replicas    = 3 # Maximal 3 Server
    min_replicas    = 1 # Mindestens 1 Server läuft immer
    cooldown_period = 60

    cpu_utilization {
      target = 0.7 # Sobald die CPU 70% erreicht, wird ein neuer Server gestartet
    }
  }
}