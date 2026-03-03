# Bereitstellung des Object Storage (Bucket) für statische Web-Inhalte
# Nutzung der EU-Multi-Region zur Gewährleistung von DSGVO-Konformität und Ausfallsicherheit

resource "google_storage_bucket" "frontend_bucket" {
  name          = "${var.project_id}-frontend-bucket"
  location      = "EU"

  # HINWEIS: Für diesen Prototyp aktiviert, um bei 'terraform destroy' 
  # eine saubere Ressourcen-Löschung durchzuführen
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  uniform_bucket_level_access = true
}

# IAM-Richtlinie zur öffentlichen Bereitstellung der Frontend-Assets
# Zwingend erforderlich, damit das Cloud CDN die statischen Dateien global ausliefern kann
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.frontend_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Automatisierte Bereitstellung des initialen Frontend-Artefakts
# Entspricht explizit dem Deployment-Schritt 2 der Architektur-Spezifikation
resource "google_storage_bucket_object" "index_html" {
  name         = "index.html"
  bucket       = google_storage_bucket.frontend_bucket.name
  content      = "<h1>Willkommen bei StockSense AI</h1><p>Das Frontend ist online!</p>"
  content_type = "text/html"
}