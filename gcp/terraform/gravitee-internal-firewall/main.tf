locals {
  firewall_rules = {
    management_to_repository_mongo = {
      description  = "Permite management acessar MongoDB no repository"
      source_ranges = var.management_subnet_cidrs
      target_tags  = var.repository_target_tags
      protocol     = "tcp"
      ports        = ["27017"]
    }
    management_to_repository_elasticsearch = {
      description  = "Permite management acessar Elasticsearch no repository"
      source_ranges = var.management_subnet_cidrs
      target_tags  = var.repository_target_tags
      protocol     = "tcp"
      ports        = ["9200"]
    }
    gateway_to_repository_mongo = {
      description  = "Permite gateway acessar MongoDB no repository"
      source_ranges = var.gateway_subnet_cidrs
      target_tags  = var.repository_target_tags
      protocol     = "tcp"
      ports        = ["27017"]
    }
    gateway_to_repository_elasticsearch = {
      description  = "Permite gateway acessar Elasticsearch no repository"
      source_ranges = var.gateway_subnet_cidrs
      target_tags  = var.repository_target_tags
      protocol     = "tcp"
      ports        = ["9200"]
    }
    gateway_to_management_api = {
      description  = "Permite gateway acessar a API de management"
      source_ranges = var.gateway_subnet_cidrs
      target_tags  = var.management_target_tags
      protocol     = "tcp"
      ports        = ["8083"]
    }
  }
}

resource "google_compute_firewall" "gravitee_internal" {
  for_each = local.firewall_rules

  project     = var.project_id
  name        = "gio-${replace(each.key, "_", "-")}"
  network     = var.network
  description = each.value.description
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags

  allow {
    protocol = each.value.protocol
    ports    = each.value.ports
  }
}
