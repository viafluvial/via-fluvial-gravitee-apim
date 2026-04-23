# Portal UI pt-BR (Gravitee APIM 3.20.32)

Este diretório gera uma imagem custom do **Portal UI** que:

- adiciona `assets/i18n/pt-br.json`
- adiciona alias `assets/i18n/pt.json` (mesmo conteúdo do `pt-br.json`)
- habilita os locales `pt` e `pt-br` no bundle (`main.*.js`)

Observação: no APIM 3.20.32, a seleção automática de idioma usa o valor base do navegador (ex.: `pt-BR` -> `pt`).

## Build

```bash
docker build -t apim-portal-ui:3.20.32-ptbr .
```

## Deploy (Swarm)

No stack de management, defina:

- `GIO_PORTAL_UI_IMAGE=apim-portal-ui:3.20.32-ptbr`

Observação: em Swarm, a imagem precisa estar disponível para o(s) nó(s) que executam o serviço `portal` (ex.: via registry).
