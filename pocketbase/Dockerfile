FROM alpine:latest

# Versión de PocketBase (se puede sobrescribir desde docker-compose)
ARG PB_VERSION=0.40.5

# Dependencias necesarias y certificados CA
RUN apk add --no-cache \
    unzip \
    ca-certificates \
    tzdata

WORKDIR /pb

# Descargar y desempaquetar PocketBase
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ && rm /tmp/pb.zip

# Carpetas necesarias
RUN mkdir -p /pb/pb_data /pb/pb_public /pb/pb_migrations /pb/pb_hooks

# Script de entrada: restaura un backup si se monta en /tmp/backup_inicial.zip
# (opcional; si no existe, arranca con una base de datos nueva)
RUN printf '%s\n' \
    '#!/bin/sh' \
    'if [ -f /tmp/backup_inicial.zip ] && [ ! -f /pb/pb_data/data.db ]; then' \
    '  echo "Restaurando backup inicial de PocketBase..."' \
    '  unzip -o /tmp/backup_inicial.zip -d /pb/pb_data/' \
    'fi' \
    'exec /pb/pocketbase serve --http=0.0.0.0:8082' \
    > /pb/entrypoint.sh && chmod +x /pb/entrypoint.sh

# Volumen para la base de datos (SQLite)
VOLUME /pb/pb_data

CMD ["/pb/entrypoint.sh"]
