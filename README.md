# via-fluvial-gravitee-apim

Projeto de implantacao do Gravitee APIM distribuido em clusters Docker Swarm no GCP, com deploy via Portainer API, exposicao via Traefik e infraestrutura de DNS/firewall via Terraform.

## Arquitetura alvo

- repository: MongoDB, Mongo Express, Elasticsearch, Kibana
- management: Gravitee Management API, Console UI, Portal UI
- gateway: Gravitee API Gateway

Dominio base:

- plataforma.prd.viafluvial.com.br

## Estrutura principal

- ansible/: playbooks de deploy, validacao e uninstall das stacks
- applications/: stacks docker-compose por camada
- gcp/terraform/gravitee-dns/: Cloud DNS da plataforma Gravitee
- gcp/terraform/gravitee-internal-firewall/: regras internas entre clusters
- gcp/config/: inventario e envs operacionais (Portainer/Ansible)
- .env.gcp.example: exemplo de variaveis para ambiente GCP

## Comandos principais

Infraestrutura GCP:

```bash
make dns-init
make dns-plan
make dns-apply

make firewall-init
make firewall-plan
make firewall-apply
```

Deploy de stacks:

```bash
make deploy-repository
make deploy-management
make deploy-gateway
make deploy-all
```

Remocao de stacks:

```bash
make uninstall-repository ALLOW_UNINSTALL=true
make uninstall-management ALLOW_UNINSTALL=true
make uninstall-gateway ALLOW_UNINSTALL=true
make uninstall-all ALLOW_UNINSTALL=true
```

## Observacoes

- O inventario operacional deve ficar em `gcp/config/inventory/<env>.ini` (GCP-first).
- Os envs de Portainer operacionais ficam em `gcp/config/portainer-*.env`.
- Nao use credenciais reais no repositorio; preencha valores locais antes da execucao.
