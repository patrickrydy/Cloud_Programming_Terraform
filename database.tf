# Bereitstellung der relationalen Cloud SQL-Datenbankinstanz
# Die explizite Abhängigkeit (depends_on) stellt sicher, dass das VPC-Peering vollständig
# etabliert ist, bevor die Datenbankinstanz im privaten Netzwerk initialisiert wird.
resource "google_sql_database_instance" "postgres_db" {
  depends_on = [google_service_networking_connection.private_vpc_connection]
  name             = "stocksense-db-instance"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    # Ressourcen-Allokation strikt limitiert auf das Free-Tier-Kontingent (Kosteneffizienz)
    tier = "db-f1-micro"
    
    ip_configuration {
      # Deaktivierung der öffentlichen IP-Adresse (Secure-by-Design-Prinzip)
      # Isoliert die Datenhaltungsschicht vom Internet zur Sicherstellung der DSGVO-Konformität
      ipv4_enabled    = false 
      private_network = google_compute_network.vpc_network.id
    }
  }
  
  # HINWEIS: Löschschutz (Deletion Protection) ist für diesen Prototyp bewusst deaktiviert.
  deletion_protection = false 
}
# Initialisierung der logischen Datenbank innerhalb der bereitgestellten Instanz
# Dient als dedizierter Speicherort
resource "google_sql_database" "default_db" {
  name     = "stocksense_user_data"
  instance = google_sql_database_instance.postgres_db.name
}