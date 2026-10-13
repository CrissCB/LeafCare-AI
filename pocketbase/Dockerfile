FROM alpine:latest

# Versión de PocketBase (puedes sobrescribirla desde docker-compose si lo deseas)
ARG PB_VERSION=0.40.5

# Instalar dependencias necesarias y certificados CA
RUN apk add --no-cache \
    unzip \
    ca-certificates \
    tzdata

# Crear usuario y grupo sin privilegios por seguridad
RUN addgroup -S pocketbase && adduser -S pocketbase -G pocketbase

WORKDIR /pb

# Descargar y desempaquetar PocketBase
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ && rm /tmp/pb.zip

# Crear carpetas necesarias
RUN mkdir -p /pb/pb_data /pb/pb_public /pb/pb_migrations /pb/pb_hooks

# Copiar el archivo zip del backup al contenedor (si existe)
COPY backup_inicial.zip /tmp/backup_inicial.zip

# Script de entrada inteligente
RUN echo '#!/bin/sh' > /pb/entrypoint.sh && \
    echo 'if [ -f /tmp/backup_inicial.zip ] && [ ! -f /pb/pb_data/data.db ]; then' >> /pb/entrypoint.sh && \
    echo '  echo "Restaurando backup inicial de PocketBase..."' >> /pb/entrypoint.sh && \
    echo '  unzip -o /tmp/backup_inicial.zip -d /pb/pb_data/' >> /pb/entrypoint.sh && \
    echo '  rm /tmp/backup_inicial.zip' >> /pb/entrypoint.sh && \
    echo 'fi' >> /pb/entrypoint.sh && \
    echo 'exec /pb/pocketbase serve --http=0.0.0.0:8082' >> /pb/entrypoint.sh && \
    chmod +x /pb/entrypoint.sh

# Asignar permisos al usuario no-root
RUN chown -R pocketbase:pocketbase /pb

# Declarar volumen para la base de datos (SQLite)
VOLUME /pb/pb_data

EXPOSE 8082

# Cambiar al usuario seguro antes de ejecutar
USER pocketbase

# Usar el script de entrada en lugar de llamar a pocketbase directamente
CMD ["/pb/entrypoint.sh"]