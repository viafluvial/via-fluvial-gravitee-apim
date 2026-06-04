variable "project_id" {
  description = "ID do projeto GCP."
  type        = string
}

variable "region" {
  description = "Regiao padrao para o provider."
  type        = string
  default     = "southamerica-east1"
}

variable "network" {
  description = "Nome da VPC dos clusters Swarm."
  type        = string
}

variable "repository_subnet_cidrs" {
  description = "CIDRs do cluster repository."
  type        = list(string)
}

variable "management_subnet_cidrs" {
  description = "CIDRs do cluster management."
  type        = list(string)
}

variable "gateway_subnet_cidrs" {
  description = "CIDRs do cluster gateway."
  type        = list(string)
}

variable "repository_target_tags" {
  description = "Tags de rede das instancias do cluster repository."
  type        = list(string)
  default     = []
}

variable "management_target_tags" {
  description = "Tags de rede das instancias do cluster management."
  type        = list(string)
  default     = []
}
