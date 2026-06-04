# Gravitee DNS (GCP)

Este modulo cria os registros Cloud DNS da plataforma Gravitee APIM no dominio `plataforma.prd.viafluvial.com.br`.

## Registros criados

- `api-console-gio.management.plataforma.prd.viafluvial.com.br`
- `console-gio.management.plataforma.prd.viafluvial.com.br`
- `portal-gio.management.plataforma.prd.viafluvial.com.br`
- `api-gateway-gio.gateway.plataforma.prd.viafluvial.com.br`
- `kibana-gio.repository.plataforma.prd.viafluvial.com.br`
- `mongo-express-gio.repository.plataforma.prd.viafluvial.com.br`
- `mongodb-gio.repository.plataforma.prd.viafluvial.com.br`
- `elasticsearch-gio.repository.plataforma.prd.viafluvial.com.br`
- Endpoints de operacao do cluster: Traefik e Portainer por area.

## Uso

```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Copie `terraform.tfvars.example` para `terraform.tfvars` e ajuste os IPs de load balancer de cada cluster.
