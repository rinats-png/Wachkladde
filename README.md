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
| `docs/NETZORDNER.md` | wie der gemeinsame Ordner funktioniert, mit Grenzen |
| `docs/GESTALTUNG.md` | die gestalterischen Entscheidungen und warum |
| `docs/MIGRATION.md` | Schritt-für-Schritt-Umstellung und Datenschema |

## Schnellstart

**Variante A – gemeinsamer Ordner im Netz (empfohlen, kein Server)**

1. Den Ordner `netzordner/` auf das Netzlaufwerk kopieren, z. B. nach
   `\\<Server>\<Freigabe>\Wachkladde\`.
2. An jedem Arbeitsplatz `Wachkladde.html` mit **Edge oder Chrome** öffnen.
3. *Einstellungen → Ordner verbinden* → genau diesen Ordner auswählen → Schreibzugriff erlauben.

Ab dann arbeiten alle gemeinsam. Es läuft kein Dienst, es wird nichts installiert,
und wer keinen Zugriff auf die Freigabe hat, sieht nichts. Details in
`netzordner/ANLEITUNG.txt`, Technik in `docs/NETZORDNER.md`.

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
- **Gemeinsamer Ordner**: mehrere Arbeitsplätze gleichzeitig ohne Server;
  Anwesenheitsanzeige, feldgenaue Zusammenführung, sichtbare Konflikthinweise.
- **Einteilungen** inklusive DGL, V-DGL, DGL-EZF und V-DGL-EZF.
- **Farben** frei konfigurierbar, drei Voreinstellungen.
- **Druck**: A4 hochkant, eine Seite je Schicht, optional „kompakt". Auf Papier
  werden Werte als Fließtext gesetzt, damit lange Bemerkungen nicht abschneiden.
- **Farbe je Eintrag**: jede Abwesenheit, jede Einteilung und jede Abstellungsart
  bekommt in den Einstellungen ihre eigene Signalfarbe — 24 Töne zur Auswahl,
  eigene Farbwerte ebenso. Einzelne BSOD-Blöcke lassen sich in der Kladde
  abweichend färben.
- **Mindestwachstärke** für regulären Dienst und Terminal 3, je Tag- und
  Nachtdienst getrennt. Erreicht = grün, unterschritten = rot. Welche
  Abwesenheitsgründe die Stärke reduzieren und welche als Terminal-3-Besetzung
  zählen, ist frei einstellbar.
- **Tastatur**: ← → wechselt den Tag, `t` springt auf heute.

## Sicherheitshinweis

Im Ordner-Betrieb ist die Zugriffskontrolle die Freigabe selbst: wer keine
NTFS-Berechtigung auf den Ordner hat, kommt an nichts heran. Die Rollen in der
Anwendung sind eine Bedienhilfe, keine Zugriffskontrolle – wer den Ordner
schreiben darf, kann alles ändern. Das ist bei der heutigen `.xlsm` genauso.

Der mitgelieferte Server (Variante C) hat keine Authentifizierung und ist für ein
geschlossenes Dienstnetz gedacht; siehe `docs/MIGRATION.md`, Abschnitt „Absicherung".
