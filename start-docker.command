#!/bin/bash
# Job Match & Apply als vollständigen Docker-Stack starten. Per Doppelklick im Finder ausführbar.
# Voraussetzung: Docker Desktop. Beim ersten Start wird gebaut (einige Minuten).
# Beenden: stop-docker.command
set -euo pipefail
cd "$(dirname "$0")"

say() { printf '\n\033[1;32m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mFehler: %s\033[0m\n' "$1"; read -r -p "Enter zum Schließen ..." _; exit 1; }

command -v docker >/dev/null 2>&1 || fail "Docker ist nicht installiert. Docker Desktop: https://www.docker.com/products/docker-desktop/"
if ! docker info >/dev/null 2>&1; then
  say "Docker Desktop wird gestartet"
  open -a Docker || fail "Docker Desktop konnte nicht gestartet werden."
  for _ in $(seq 1 90); do docker info >/dev/null 2>&1 && break; sleep 2; done
  docker info >/dev/null 2>&1 || fail "Docker Desktop antwortet nicht."
fi

say "Submodules prüfen"
if command -v git >/dev/null 2>&1; then git submodule update --init --recursive; fi
[ -f integrations/bewerbungs-schreib-assistent/SKILL.md ] || fail "Submodules fehlen. Bitte 'git submodule update --init --recursive' ausführen."

mkdir -p .local-data .application-work

if lsof -nP -iTCP:4201 -sTCP:LISTEN >/dev/null 2>&1 && ! docker compose ps --status running --services 2>/dev/null | grep -q web; then
  fail "Port 4201 ist belegt. Läuft die App schon ohne Docker (start-mac.command)? Dann zuerst beenden."
fi

say "Baue und starte den Stack"
docker compose up -d --build

say "Warte auf die App"
for _ in $(seq 1 120); do
  if curl -fsS -o /dev/null http://127.0.0.1:4201/api/health; then
    open "http://localhost:4201"
    say "Läuft: http://localhost:4201  –  Beenden mit stop-docker.command"
    exit 0
  fi
  sleep 2
done
docker compose logs --tail 50
fail "Die App hat nicht rechtzeitig geantwortet. Die Logs stehen oben."
