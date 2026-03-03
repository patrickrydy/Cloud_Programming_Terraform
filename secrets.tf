# Bereitstellung des Secrets im GCP Secret Manager
resource "google_secret_manager_secret" "eodhd_api_key" {
  secret_id = "eodhd-api-key"

  replication {
    auto {}
  }
}

# Initialisierung der Secret-Version mit der lokalen Umgebungsvariable
resource "google_secret_manager_secret_version" "eodhd_api_key_version" {
  secret      = google_secret_manager_secret.eodhd_api_key.id
  secret_data = var.eodhd_api_key
}

variable "eodhd_api_key" {
  description = "Der geheime API Key für EODHD (wird lokal injiziert)"
  type        = string
  sensitive   = true  #maskiert den Wert in den Terraform-Logs
  default     = "DUMMY_KEY_FUER_DAS_DEPLOYMENT"
}