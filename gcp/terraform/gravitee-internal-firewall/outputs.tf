output "firewall_rules" {
  description = "Regras de firewall internas criadas para comunicacao entre clusters Gravitee."
  value = {
    for key, fw in google_compute_firewall.gravitee_internal :
    key => fw.name
  }
}
