#!/bin/bash
# Beendet den Docker-Stack von Job Match & Apply. Daten in .local-data/ bleiben erhalten.
set -euo pipefail
cd "$(dirname "$0")"
docker compose down
printf '\n\033[1;32m==> Gestoppt. Deine Daten bleiben in .local-data/ erhalten.\033[0m\n'
