#!/bin/bash
# Job Match & Apply direkt auf dem Mac starten (ohne Docker). Per Doppelklick im Finder ausführbar.
# Prüft Homebrew, Node.js 22 und Git, installiert fehlende Abhängigkeiten und öffnet danach den Browser.
# Beenden: Ctrl + C in diesem Fenster.
set -euo pipefail
cd "$(dirname "$0")"

say() { printf '\n\033[1;32m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mFehler: %s\033[0m\n' "$1"; read -r -p "Enter zum Schließen ..." _; exit 1; }

if ! command -v brew >/dev/null 2>&1; then
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$candidate" ] && eval "$("$candidate" shellenv)" && break
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  say "Homebrew fehlt – Installation startet (Mac-Passwort wird abgefragt)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi

if ! brew list node@22 >/dev/null 2>&1; then say "Installiere Node.js 22"; brew install node@22; fi
command -v git >/dev/null 2>&1 || { say "Installiere Git"; brew install git; }
export PATH="$(brew --prefix node@22)/bin:$PATH"
node_major="$(node --version | sed -E 's/^v([0-9]+).*/\1/')"
[ "$node_major" -ge 22 ] || fail "Node.js 22 oder neuer wird benötigt, gefunden: $(node --version)"

say "Submodules prüfen"
git submodule update --init --recursive

# npm install nur, wenn node_modules fehlt oder älter als die Lockfile ist.
needs_install() { [ ! -d "$1/node_modules" ] || [ "$1/package-lock.json" -nt "$1/node_modules" ]; }
for dir in . server web; do
  if needs_install "$dir"; then
    say "Abhängigkeiten installieren: $dir"
    npm --prefix "$dir" install --no-audit --no-fund
    touch "$dir/node_modules"
  fi
done

if lsof -nP -iTCP:4201 -sTCP:LISTEN >/dev/null 2>&1 || lsof -nP -iTCP:3000 -sTCP:LISTEN >/dev/null 2>&1; then
  fail "Port 4201 oder 3000 ist schon belegt. Läuft die App bereits (z. B. per Docker)? Dann zuerst beenden."
fi

# Browser öffnen, sobald die Oberfläche antwortet.
(
  for _ in $(seq 1 180); do
    if curl -fsS -o /dev/null http://127.0.0.1:4201/ && curl -fsS -o /dev/null http://127.0.0.1:3000/api/health; then
      open "http://localhost:4201"
      exit 0
    fi
    sleep 1
  done
) &

say "Starte Job Match & Apply – Browser öffnet sich automatisch. Beenden mit Ctrl + C."
npm run dev
