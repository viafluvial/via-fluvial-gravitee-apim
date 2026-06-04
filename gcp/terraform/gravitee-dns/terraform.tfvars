# Gravitee DNS - PRD
# Preencha com os valores reais dos load balancers de cada cluster.

project_id     = "vfa-plataforma-prd-k0ru"
dns_project_id = "vfa-dns-core"
region         = "us-central1"
dns_zone_name  = "zona-dns-viafluvial-com-br"

dns_domain  = "plataforma.prd.viafluvial.com.br."
create_zone = false
ttl         = 300

# Load balancers por cluster
repository_lb_ip = "34.49.191.184"
management_lb_ip = "34.120.146.206"
gateway_lb_ip    = "130.211.25.83"
