# Definition der Terraform-Umgebung und Version
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Initialisierung des Google Cloud Providers anhand der definierten Projekt-Variablen
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}