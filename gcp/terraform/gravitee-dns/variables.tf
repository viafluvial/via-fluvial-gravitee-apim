variable "project_id" {
  description = "ID do projeto GCP."
  type        = string
}

variable "dns_project_id" {
  description = "Projeto GCP onde a zona Cloud DNS está hospedada. Se null, usa project_id."
  type        = string
  default     = null
}

variable "region" {
  description = "Regiao GCP usada pelo provider."
  type        = string
  default     = "southamerica-east1"
}

variable "dns_zone_name" {
  description = "Nome da zona Cloud DNS."
  type        = string
  default     = "viafluvial-plataforma-prd"
}

variable "dns_domain" {
  description = "Dominio base da zona com ponto final (ex.: plataforma.prd.viafluvial.com.br.)."
  type        = string
  default     = "plataforma.prd.viafluvial.com.br."

  validation {
    condition     = endswith(var.dns_domain, ".")
    error_message = "dns_domain deve terminar com ponto final."
  }
}

variable "create_zone" {
  description = "Se true cria a zona; se false usa zona existente."
  type        = bool
  default     = false
}

variable "ttl" {
  description = "TTL dos registros DNS."
  type        = number
  default     = 300
}

variable "repository_lb_ip" {
  description = "IP publico do load balancer do cluster repository."
  type        = string
}

variable "management_lb_ip" {
  description = "IP publico do load balancer do cluster management."
  type        = string
}

variable "gateway_lb_ip" {
  description = "IP publico do load balancer do cluster gateway."
  type        = string
}
