variable "project_id" {
  description = "Projekt ID"
  type        = string
  default     = "stocksense-ai-488314" 
}

variable "region" {
  description = "Die primäre GCP-Region (DACH-Raum)"
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "Die primäre GCP-Zone"
  type        = string
  default     = "europe-west3-a"
}
