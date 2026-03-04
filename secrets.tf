# Bereitstellung des Secrets im GCP Secret Manager
resource "google_secret_manager_secret" "eodhd_api_key" {
  secret_id = "eodhd-api-key"
  replication {
    auto {}
  }
}

# Den Wert dynamisch und unsichtbar aus der Shell laden
resource "google_secret_manager_secret_version" "eodhd_api_key_version" {
  secret      = google_secret_manager_secret.eodhd_api_key.id
  secret_data = var.eodhd_api_key
}

variable "eodhd_api_key" {
  description = "Der geheime API Key für EODHD (wird lokal über die Shell injiziert)"
  type        = string
  sensitive   = true  # Maskiert den Wert in den Terraform-Logs
}
