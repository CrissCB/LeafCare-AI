# Etapa 1: compilar la app Flutter Web
FROM debian:bookworm-slim AS build

# Versión de Flutter fijada para que coincida con el proyecto (Dart 3.13.5)
ARG FLUTTER_VERSION=3.47.6

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Instalar el SDK de Flutter desde el tarball oficial
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o /tmp/flutter.tar.xz \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory "${FLUTTER_HOME}"

WORKDIR /app

# Copiar dependencias primero para aprovechar la caché de capas
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar el resto del proyecto y compilar
COPY . .
RUN flutter build web --release

# Etapa 2: servir los archivos estáticos con nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
