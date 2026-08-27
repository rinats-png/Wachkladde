# Wachkladde – HTML-Ablösung der Excel-Kladde

Ersetzt `Wachkladde_<Monat>_<Jahr>.xlsm` (35 Blätter, VBA, Blattschutz) durch eine
einzelne HTML-Datei mit lokaler Speicherung, Netzwerk-Synchronisation, Druckansicht,
Farbanpassung und verwaltbaren Dienstgruppen.

## Dateien

| Datei | Zweck |
|---|---|
| `wachkladde.html` | die komplette Anwendung – eine Datei, keine Abhängigkeiten, offline lauffähig |
| `server/server.js` | optionaler Sync-Server (Node.js, ohne npm-Pakete, ~110 Zeilen) |
| `tools/import_xlsm.py` | Migration: liest die vorhandene `.xlsm` und erzeugt `wachkladde.json` |
| `docs/MIGRATION.md` | Schritt-für-Schritt-Umstellung und Datenschema |

## Schnellstart

**Variante A – nur ein Rechner (0 Minuten Einrichtung)**

1. `wachkladde.html` auf den Rechner kopieren, doppelklicken.
2. Alles wird im Browser gespeichert (localStorage) und überlebt Neustarts.
3. Weitergabe/Backup über *Einstellungen → Daten → JSON exportieren*.

**Variante B – mehrere Arbeitsplätze (ca. 15 Minuten)**

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
- **Farben** frei konfigurierbar, drei Voreinstellungen.
- **Druck**: A4 hochkant, eine Seite je Schicht, optional „kompakt".

## Sicherheitshinweis

Der mitgelieferte Server hat keine Authentifizierung. Er ist für ein geschlossenes
Dienstnetz gedacht. Für den Produktivbetrieb siehe `docs/MIGRATION.md`,
Abschnitt „Absicherung".
