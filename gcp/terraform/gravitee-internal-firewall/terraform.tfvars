# Gravitee Internal Firewall - PRD
# Ajuste CIDRs e tags conforme os clusters reais no GCP.

project_id = "vfa-network-prd-k0ru"
region     = "us-central1"
network    = "vpc-prd"

# Sub-redes por cluster
repository_subnet_cidrs = ["10.60.4.0/22"]
management_subnet_cidrs = ["10.60.4.0/22"]
gateway_subnet_cidrs    = ["10.60.4.0/22"]

# Tags de destino dos nós que recebem as regras
repository_target_tags = ["swarm-manager"]
management_target_tags = ["swarm-manager"]
