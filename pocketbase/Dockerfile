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

# Copiar el backup inicial dentro de la imagen.
# Se restaura solo cuando la base de datos está vacía (primer arranque).
COPY backup_ejemplo_20102026.zip /tmp/backup_inicial.zip

# Script de entrada: restaura el backup si la base de datos todavía no existe.
# Si ya existe data.db, no toca nada y arranca con los datos actuales.
RUN printf '%s\n' \
    '#!/bin/sh' \
    'if [ -f /tmp/backup_inicial.zip ] && [ ! -f /pb/pb_data/data.db ]; then' \
    '  echo "Restaurando backup inicial de PocketBase..."' \
    '  unzip -o /tmp/backup_inicial.zip -d /pb/pb_data/' \
    '  rm -f /tmp/backup_inicial.zip' \
    'fi' \
    'exec /pb/pocketbase serve --http=0.0.0.0:8082' \
    > /pb/entrypoint.sh && chmod +x /pb/entrypoint.sh

# Volumen para la base de datos (SQLite)
VOLUME /pb/pb_data

CMD ["/pb/entrypoint.sh"]
