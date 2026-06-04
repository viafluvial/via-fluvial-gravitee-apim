# Gravitee Internal Firewall (GCP)

Este modulo cria regras de firewall internas para permitir somente o trafego entre clusters necessario ao Gravitee APIM.

## Fluxos liberados

- management -> repository: TCP 27017 (MongoDB)
- management -> repository: TCP 9200 (Elasticsearch)
- gateway -> repository: TCP 27017 (MongoDB)
- gateway -> repository: TCP 9200 (Elasticsearch)
- gateway -> management: TCP 8083 (Management API)

## Uso

```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Defina `repository_subnet_cidrs`, `management_subnet_cidrs`, `gateway_subnet_cidrs` e as tags de destino de cada cluster.
