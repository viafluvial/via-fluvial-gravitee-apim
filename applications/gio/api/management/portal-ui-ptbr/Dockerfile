FROM graviteeio/apim-portal-ui:3.20.32

COPY pt-br.json /usr/share/nginx/html/assets/i18n/pt-br.json

RUN set -eux; \
  cp /usr/share/nginx/html/assets/i18n/pt-br.json /usr/share/nginx/html/assets/i18n/pt.json; \
  main="$(ls /usr/share/nginx/html/main.*.js)"; \
  grep -Fq 'locales:["en","fr","cs"]' "$main"; \
  sed -i 's/locales:\[\"en\",\"fr\",\"cs\"\]/locales:["en","fr","cs","pt","pt-br"]/g' "$main"; \
  grep -Fq 'locales:["en","fr","cs","pt","pt-br"]' "$main"
