# Wachkladde – HTML-Ablösung der Excel-Kladde

Ersetzt `Wachkladde_<Monat>_<Jahr>.xlsm` (35 Blätter, VBA, Blattschutz) durch eine
einzelne HTML-Datei mit lokaler Speicherung, Netzwerk-Synchronisation, Druckansicht,
Farbanpassung und verwaltbaren Dienstgruppen.

Die Oberfläche ist bewusst **keine Tabelle mehr**, sondern eine Schichtkonsole:
Tagesleiste statt Datumsfeld, Besetzungsanzeige statt Zählspalte, farbcodierte
Einträge statt gleichförmiger Zellen, Ampel für die Mindestwachstärke. Nur der
**Ausdruck** bleibt die vertraute Papierform — siehe `docs/GESTALTUNG.md`.

## Dateien

| Datei | Zweck |
|---|---|
| `netzordner/` | **fertiger Ordner zum Kopieren auf das Netzlaufwerk** – enthält die Anwendung, eine Kurzanleitung und die Datenablage |
| `wachkladde.html` | Quelldatei der Anwendung (identisch mit `netzordner/Wachkladde.html`) |
| `server/server.js` | optionaler Sync-Server (Node.js, ohne npm-Pakete, ~110 Zeilen) |
| `tools/import_xlsm.py` | Migration: liest die vorhandene `.xlsm` und erzeugt `wachkladde.json` |
| `docs/BETRIEB.md` | **Betrieb im Dienstnetz: Bereitstellung und Schreibrechte** |
| `server/wachkladde-server.ps1` | Windows-Server ohne Installation, mit Rechteprüfung |
| `docs/NETZORDNER.md` | wie der gemeinsame Ordner funktioniert, mit Grenzen |
| `docs/GESTALTUNG.md` | die gestalterischen Entscheidungen und warum |
| `docs/MIGRATION.md` | Schritt-für-Schritt-Umstellung und Datenschema |

## Schnellstart

**Variante A – ein Rechner stellt sie bereit (empfohlen)**

1. Ordner auf das Netzlaufwerk kopieren.
2. Auf einem Rechner der Wache **`server/Wachkladde-Server starten.cmd`** doppelklicken —
   es wird **nichts installiert**, das Skript nutzt den in Windows eingebauten
   `HttpListener`.
3. Alle anderen Arbeitsplätze öffnen `http://<Rechnername>:8080/` — ein Lesezeichen
   genügt.

Läuft in **jedem** Browser, auch Firefox. Wer schreiben darf, steht in
`server/rechte.json`; die Prüfung sitzt auf dem Server und ist damit verbindlich.
Alles Weitere in **`docs/BETRIEB.md`**.

> **Wichtig:** Ein Doppelklick auf `Wachkladde.html` (also `file://`) kann **keinen
> Ordner verbinden** — Browser sperren den Ordnerzugriff für diesen Ursprung. Die
> Ordner-Variante funktioniert nur, wenn die Seite über `http://` ausgeliefert wird.

**Variante B – nur ein Rechner (0 Minuten Einrichtung)**

1. `wachkladde.html` auf den Rechner kopieren, doppelklicken.
2. Alles wird im Browser gespeichert (localStorage) und überlebt Neustarts.
3. Weitergabe/Backup über *Einstellungen → Daten → JSON exportieren*.

**Variante C – eigener Sync-Server (wenn ein Dienst laufen darf)**

```bash
node server/server.js --port 8080          # auf einem Rechner der Wache
```
Alle Arbeitsplätze rufen `http://<rechnername>:8080/` auf. In *Einstellungen →
Synchronisation*: Modus „Server", URL eintragen, Intervall z. B. 10 s.
Der Server braucht keine Datenbank – er schreibt `server/data/ops.jsonl` und
`server/data/snapshot.json`.

**Daten aus Excel übernehmen**

```bash
pip install openpyxl
python3 tools/import_xlsm.py Wachkladde_08_August_2026.xlsm > wachkladde.json
```
Dann in der Anwendung *Einstellungen → Daten → JSON importieren*.

`tools/paket_bauen.sh` aktualisiert `netzordner/` nach einer Änderung an `wachkladde.html`.

## Funktionsumfang

- **Tagesansicht** mit Tagdienst und Nachtdienst nebeneinander, Datumsnavigation.
- **Dienstgruppen-Rotation** als Kette über die DG-Nummern (wie im Original),
  mit Anfangsdatum, Anfangs-DG und editierbaren Zuordnungstabellen;
  pro Schicht ist ein manueller Override möglich (`≠ Plan n ↺`).
- **Personaltabelle** mit Abwesenheit, automatischer „Ist"-Zählung, Einteilung,
  Bemerkung; Ergänzungsdienst als eigener Abschnitt.
- **Abstellungen/BSOD** als Blöcke mit frei definierbaren Feldern.
- **Lehrgänge/Gerichtstermine, Sonstiges, Bestandsübergabe, DGL-Übergabe.**
- **Stammdaten**: Beamte je Dienstgruppe anlegen, umsortieren, deaktivieren –
  die Nummerierung ist immer fortlaufend und wird automatisch neu vergeben.
- **Rollen**: Admin, DGL, Beamter (nur eigene Zeile), Leser.
- **Zugriffsschutz mit Passwort** (ohne Server): ein Passwort für den Schreibmodus,
  optional ein zweites für die Verwaltung; Selbstsperre nach Untätigkeit. Das
  Passwort liegt als Hash mit Salz vor, nicht im Klartext. Schützt vor
  versehentlichem Ändern — die verbindliche Trennung leistet der Server.
- **Gemeinsamer Ordner**: mehrere Arbeitsplätze gleichzeitig ohne Server;
  Anwesenheitsanzeige, feldgenaue Zusammenführung, sichtbare Konflikthinweise.
- **Einteilungen** inklusive DGL, V-DGL, DGL-EZF und V-DGL-EZF.
- **Farben** frei konfigurierbar, drei Voreinstellungen.
- **Druck**: A4 hochkant, **eine Seite je Schicht** — geprüft für alle 62 Schichten
  eines vollen Monats. In Farbe: die Signalfarben bleiben erhalten, ein
  Schwarzweißdruck bleibt trotzdem vollständig lesbar. Werte werden als Fließtext
  gesetzt, damit lange Bemerkungen nicht abschneiden; der Unterschriftsbereich
  steht immer vollständig auf dem Blatt.
- **Farbe je Eintrag**: jede Abwesenheit, jede Einteilung und jede Abstellungsart
  bekommt in den Einstellungen ihre eigene Signalfarbe — 24 Töne zur Auswahl,
  eigene Farbwerte ebenso. Einzelne BSOD-Blöcke lassen sich in der Kladde
  abweichend färben.
- **Mindestwachstärke** für regulären Dienst und Terminal 3 — getrennt nach
  Tag- und Nachtdienst und **für jeden Wochentag einzeln**. Erreicht = grün,
  unterschritten = rot. Welche Abwesenheitsgründe die Stärke reduzieren und
  welche als Terminal-3-Besetzung zählen, ist frei einstellbar.
- **Tastatur**: ← → wechselt den Tag, `t` springt auf heute, `/` öffnet die Suche,
  Strg+Z macht rückgängig, Strg+Y wiederholt.
- **Auswertung**: Fehlzeiten je Beamter — einen Namen und einen Grund wählen und
  ablesen, wie oft im laufenden Monat, in den letzten 3 und 6 Monaten, im laufenden
  Jahr und im Vorjahr. Ein Klick auf eine Zahl listet die einzelnen Tage mit
  Wochentag auf. Dazu Monatsübersicht als Kalenderraster, unterschrittene
  Wachstärken, Terminal-3-Einsätze und Abstellungsaufkommen — auch ausdruckbar.
- **Monatsabschluss**: legt den Monat als JSON und als eigenständige, druckfertige
  HTML im Archiv des Netzordners ab, verdichtet den Ordner und sperrt die Tage
  gegen Änderungen. Admin und DGL können wieder entsperren.
- **Zeiträume je Zeile**: optionale Uhrzeit von–bis, dazu Folgeeinträge für einen
  Statuswechsel im Dienst („bis 12:00 Wache, danach BSOD").
- **Terminal 3 füllt sich selbst**: wer als Abwesenheit einen Terminal-3-Grund
  bekommt, erscheint automatisch im Block „Wache Terminal 3" unter *noch offen*.
  Von dort lassen sich die Namen mit ↑ ↓ auf L-Wache, Wache und Streife verteilen.
  Nimmt man den Grund zurück, verschwindet der Name wieder — von Hand gesetzte
  Namen bleiben unberührt.
- **Versetzung**: ein Beamter kann zum Stichtag in eine andere Dienstgruppe
  wechseln; bereits erfasste Tage bleiben unverändert.
- **Suche** über alle erfassten Tage nach Namen, mit Sprung zum Tag.
- **Warnband**, wenn der Netzordner nicht verbunden oder nicht erreichbar ist —
  samt Zahl der noch nicht übertragenen Änderungen.

## Sicherheitshinweis

Beim Serverbetrieb entscheidet `server/rechte.json`, wer schreiben darf; geprüft
wird auf dem Server, also verbindlich. Den Benutzer meldet Windows automatisch
(integrierte Anmeldung).

Die Rollen in der Anwendung (DGL / Beamter / Leser) sind demgegenüber eine
**Bedienhilfe** — sie verhindern Vertipper, keinen Zugriff.

Im Ordner-Betrieb ist die Zugriffskontrolle die Freigabe selbst: die Anwendung
prüft beim Verbinden, ob sie schreiben darf, und schaltet sonst in den Lesebetrieb.
