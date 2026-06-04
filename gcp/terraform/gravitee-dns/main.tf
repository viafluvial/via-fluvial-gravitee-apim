locals {
  dns_project_id = coalesce(var.dns_project_id, var.project_id)
}

resource "google_project_service" "dns" {
  project = local.dns_project_id
  service = "dns.googleapis.com"

  disable_on_destroy = false
}

resource "google_dns_managed_zone" "this" {
  count = var.create_zone ? 1 : 0

  project    = local.dns_project_id
  name       = var.dns_zone_name
  dns_name   = var.dns_domain
  visibility = "public"

  depends_on = [google_project_service.dns]
}

data "google_dns_managed_zone" "existing" {
  count = var.create_zone ? 0 : 1

  project = local.dns_project_id
  name    = var.dns_zone_name

  depends_on = [google_project_service.dns]
}

locals {
  zone_name = var.create_zone ? google_dns_managed_zone.this[0].name : data.google_dns_managed_zone.existing[0].name

  dns_records = {
    "api-console-gio.management"        = var.management_lb_ip
    "console-gio.management"            = var.management_lb_ip
    "portal-gio.management"             = var.management_lb_ip
    "api-gateway-gio.gateway"           = var.gateway_lb_ip
    "kibana-gio.repository"             = var.repository_lb_ip
    "mongo-express-gio.repository"      = var.repository_lb_ip
    "mongodb-gio.repository"            = var.repository_lb_ip
    "elasticsearch-gio.repository"      = var.repository_lb_ip
    "traefik.repository"                = var.repository_lb_ip
    "portainer.repository"              = var.repository_lb_ip
    "traefik.management"                = var.management_lb_ip
    "portainer.management"              = var.management_lb_ip
    "traefik.gateway"                   = var.gateway_lb_ip
    "portainer.gateway"                 = var.gateway_lb_ip
  }
}

resource "google_dns_record_set" "a_records" {
  for_each = local.dns_records

  project      = local.dns_project_id
  managed_zone = local.zone_name
  name         = "${each.key}.${trim(var.dns_domain, ".")}."
  type         = "A"
  ttl          = var.ttl
  rrdatas      = [each.value]
}
