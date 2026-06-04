output "zone_name" {
  description = "Nome da zona utilizada."
  value       = local.zone_name
}

output "zone_nameservers" {
  description = "Nameservers da zona criada (vazio quando create_zone=false)."
  value       = var.create_zone ? google_dns_managed_zone.this[0].name_servers : []
}

output "records" {
  description = "FQDNs e IPs publicados para Gravitee e componentes de cluster."
  value = {
    for key, record in google_dns_record_set.a_records :
    key => {
      name    = record.name
      rrdatas = record.rrdatas
    }
  }
}
