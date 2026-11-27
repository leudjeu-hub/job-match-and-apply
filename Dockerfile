# syntax=docker/dockerfile:1
#
# Vollständiger Stack für Job Match & Apply. Gestartet wird er über docker-compose.yml:
#   target "api" – Express-API (Node 22, tsx) + Python 3.12 für den Bewerbungs-Assistenten + OCR-Tools
#   target "web" – nginx liefert die gebaute Angular-Oberfläche aus und leitet /api an die API weiter
#
# Die API lauscht weiterhin nur auf 127.0.0.1 im Container. Der web-Container teilt sich deren
# Netzwerk-Namensraum (network_mode: service:api) und ist der einzige Eingang.

FROM node:22-bookworm-slim AS node

FROM python:3.12-slim-bookworm AS base
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates poppler-utils tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir PyYAML
WORKDIR /app

# Abhängigkeiten getrennt vom Quellcode, damit Codeänderungen den npm-Cache nicht verwerfen.
FROM base AS deps
COPY package.json package-lock.json ./
COPY server/package.json server/package-lock.json server/
COPY web/package.json web/package-lock.json web/
RUN npm ci --no-audit --no-fund \
 && npm --prefix server ci --no-audit --no-fund \
 && npm --prefix web ci --no-audit --no-fund

FROM deps AS web-build
COPY web web
RUN npm --prefix web run build

FROM nginx:1.27-alpine AS web
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=web-build /app/web/dist/web/browser /usr/share/nginx/html

FROM deps AS api
COPY . .
RUN test -f integrations/bewerbungs-schreib-assistent/SKILL.md \
 || (echo "Submodules fehlen: vorher 'git submodule update --init --recursive' ausführen." >&2 && exit 1)
ENV PORT=3000 \
    ALLOW_EXTERNAL_PORTALS=0
WORKDIR /app/server
# node selbst ist PID-1-Kind von tini (compose: init: true) und bekommt SIGTERM direkt.
CMD ["node", "--import", "tsx", "src/index.ts"]
