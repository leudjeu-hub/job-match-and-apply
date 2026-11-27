# Stack von Job Match & Apply

Lokale Anwendung für Jobsuche, Bewerbungs-CRM, Lebenslauf-Studio und KI-gestützte Bewerbungsentwürfe.
Alle Daten bleiben auf dem eigenen Rechner. Diese Seite beschreibt die Bausteine und die drei Startwege.

## Überblick

```text
Browser ── http://localhost:4201
   │
   ▼
Angular-Oberfläche (web/)               Entwicklung: ng serve mit Proxy · Docker: nginx
   │  /api  (HTTP, Server-Sent Events, WebSocket)
   ▼
Express-API (server/) auf 127.0.0.1:3000
   ├── Matching, Bewerbungs-CRM, Mail-Vault, Lebenslauf-Studio, Export
   ├── Agent Control Center ── Codex / Claude Code / OpenCode / OpenRouter (optional)
   ├── JobSourcePort ──────── Demo-Daten oder job-search-mcp (Python, stdio)
   └── ApplicationAssistant ─ bewerbungs-schreib-assistent (Python-CLI)
   │
   ▼
.local-data/  ·  .application-work/      lokal, verschlüsselt wo sensibel, nie in Git
```

## Bausteine

| Schicht | Technik | Version | Ort |
|---|---|---|---|
| Laufzeit | Node.js, npm | 22 LTS, npm 10 | – |
| Oberfläche | Angular (Standalone, Signals), RxJS, SCSS | 22.1, 7.8 | `web/` |
| API | Express, TypeScript, tsx | 5.1, 6.0, 4.20 | `server/` |
| Validierung | Zod, JSON-Schema-Verträge | 4.0 | `contracts/v1/` |
| Agenten-Protokolle | Model Context Protocol SDK, WebSocket (`ws`) | 1.17, 8.21 | `server/src/agents/` |
| Dokumente | `docx`, `pdfkit`, `pdf-parse`, `mammoth`, `jszip`, `htmlparser2` | – | `server/src/services/` |
| Mail | `imapflow`, `mailparser`, `smtp-server` (nur Empfang) | – | `server/src/services/` |
| Rechtschreibung | `nspell` mit `dictionary-de` / `dictionary-en` | – | lokal, kein Webdienst |
| Python-Komponenten | Python, PyYAML | 3.12 | `integrations/` (Git-Submodules) |
| Jobsuche | `job-search-mcp` (MCP über stdio, Camoufox-Login) | Submodule | `integrations/job-search-mcp` |
| Bewerbungsfachlichkeit | `bewerbungs-schreib-assistent` (Claims, ATS, Stil) | Submodule | `integrations/bewerbungs-schreib-assistent` |
| OCR / PDF | Poppler (`pdftotext`, `pdftoppm`), Tesseract `deu`+`eng` | System | optional, `npm run diagnose` |
| Tests | Vitest, Supertest, Playwright, axe-core | 4.0, 7.1, 1.62 | `server/`, `web/e2e/` |
| CI | GitHub Actions (Ubuntu + Windows) | – | `.github/workflows/ci.yml` |

## Ports und Daten

| Was | Wo | Bemerkung |
|---|---|---|
| Oberfläche | `http://localhost:4201` | einziger Einstieg im Browser |
| API | `127.0.0.1:3000` | nur lokal; lehnt fremde `Host`/`Origin` ab (DNS-Rebinding-Schutz) |
| Lokaler SMTP-Empfang (optional) | `127.0.0.1:2525` | `npm run mail:server`, versendet nichts |
| Konfiguration, Profile, Schlüssel, Agentenläufe | `.local-data/` | AES-256-GCM für Identitäten, Mails, API-Keys |
| Bewerbungsarbeitsstände | `.application-work/` | nie in Git |

## Startwege

### 1. Mac per Doppelklick (empfohlen für den Alltag)

`start-mac.command` im Finder doppelklicken. Das Skript prüft Homebrew, Node.js 22 und Git, lädt die
Submodules, installiert fehlende Abhängigkeiten, startet API und Oberfläche und öffnet den Browser.
Beenden mit `Ctrl + C` im Terminalfenster.

**Echte Jobsuche auf dem Mac (einmalig):** Ohne diesen Schritt liefert die Suche Demo-Daten.

```bash
npm run setup:integrations:mac   # Python-3.12-Venv per uv, job-search-mcp, Camoufox, Offline-Smoke
```

Danach in der App unter **Quellen & MCP** die Runtime **Nativ (macOS)** wählen und den Portalzugriff
bewusst freigeben. Für den Bewerbungs-Assistenten zusätzlich `python3 -m pip install --user PyYAML`.

### 2. Docker (vollständiger Stack mit Python und OCR)

Voraussetzung: Docker Desktop.

```bash
docker compose up -d --build      # oder: start-docker.command doppelklicken
docker compose down               # oder: stop-docker.command
```

| Dienst | Image-Ziel | Inhalt |
|---|---|---|
| `api` | `Dockerfile` → `api` | Node 22 + Python 3.12 + PyYAML + Poppler + Tesseract, startet `server/src/index.ts` |
| `web` | `Dockerfile` → `web` | nginx mit gebauter Angular-Oberfläche, leitet `/api` inkl. WebSocket/SSE weiter |

`web` teilt sich den Netzwerk-Namensraum von `api`; so bleibt die API auf `127.0.0.1` gebunden. Der Port
4201 wird nur auf `127.0.0.1` des Rechners veröffentlicht, nie im lokalen Netzwerk. `.local-data/` und
`.application-work/` werden aus dem Projektordner eingebunden – Docker- und Mac-Start teilen dieselben
Daten. Nicht beide gleichzeitig starten.

### 3. Manuell (Entwicklung, alle Systeme)

```bash
git submodule update --init --recursive
npm install && npm --prefix server install && npm --prefix web install
npm run dev        # API (tsx watch) + Angular-Dev-Server mit Proxy
```

Unter Windows `npm.cmd` statt `npm` verwenden. Tests, Build und Prüfungen: siehe `AGENTS.md`.

## Grenzen je Startweg

| Funktion | Mac | Docker | Windows/WSL |
|---|---|---|---|
| Demo-Modus, CRM, Lebenslauf-Studio, Export | ja | ja | ja |
| OCR für gescannte Lebensläufe | mit `brew install poppler tesseract tesseract-lang` | ja | per WSL-Paketen |
| Bewerbungs-Assistent (Python) | mit `python3` + PyYAML | ja | ja |
| Echte Portalsuche über `job-search-mcp` | ja, nach `npm run setup:integrations:mac` | nein (nur Demo-Daten) | ja |
| Sichtbarer StepStone-Login über `job-search-mcp` | möglich nach Setup (Camoufox-Fenster, noch nicht erprobt) | nein (kein Bildschirm im Container) | ja (vorgesehener Weg) |
| Agenten Claude Code / OpenCode in Bubblewrap-Sandbox | nein | nein | ja (WSL) |
| OpenRouter-Agenten (API-Key) | ja | ja | ja |

Externe Portale bleiben überall gesperrt (`ALLOW_EXTERNAL_PORTALS=0`), bis der Zugriff in der Oberfläche
unter **Quellen & MCP** ausdrücklich bestätigt wird.

## Bedienung und Doku

| Was | Wo |
|---|---|
| Interaktive Bedienungsanleitung (Präsentation, offline) | [`../JobMatch-Bedienungsanleitung.html`](../JobMatch-Bedienungsanleitung.html), liegt neben dem Projektordner |
| Bedienungsanleitung als Dokument | [Bedienungsanleitung JobMatch & Apply](https://claude.ai/artifact/FmSpkJEB1HVFkh267BG3Y6) |
| UI/UX- und Technik-Audit mit Umsetzungsstand | [Audit JobMatch & Apply](https://claude.ai/artifact/WzAoQ23fJ3iX1D6YHUiZkG) |
| Interaktive Fassung dieser Seite | [`stack.html`](stack.html) |
