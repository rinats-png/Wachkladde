# Umsetzungsvarianten für Persistenz und Mehrbenutzerbetrieb

Alle Varianten nutzen dieselbe `wachkladde.html`; unterschiedlich ist nur, was
dahinter liegt.

## A – Nur Browser (localStorage), Austausch über JSON-Export

* **Aufwand:** ~0. Datei doppelklicken.
* **Dafür:** keine Infrastruktur, keine Freigabe, offline, keine IT-Anmeldung nötig.
* **Dagegen:** kein gleichzeitiges Arbeiten; Daten hängen an Rechner *und*
  Browserprofil; ein gelöschtes Profil löscht die Kladde.
* **Geeignet für:** Pilotbetrieb, ein DGL-Arbeitsplatz.

## B – Datei auf dem Dienstlaufwerk + manueller Import/Export

* **Aufwand:** ~0, nur eine Ablagekonvention.
* **Dafür:** Backup läuft über das vorhandene Laufwerks-Backup mit.
* **Dagegen:** Zusammenführen ist Handarbeit; genau das Problem der heutigen `.xlsm`.
* **Geeignet für:** Übergangsphase.

## C – Der mitgelieferte Node-Sync-Server ← **Empfehlung**

* **Aufwand:** ~15 Minuten. `node server/server.js`, ein freier Port, fertig.
  Keine npm-Pakete, keine Datenbank, eine Datei als Speicher.
* **Dafür:** echter Mehrbenutzerbetrieb, feldgenaue Zusammenführung, vollständiges
  Änderungsprotokoll (`ops.jsonl`), liefert die HTML-Datei gleich mit aus,
  läuft auf einem beliebigen Rechner der Wache oder als Dienst.
* **Dagegen:** jemand muss den Prozess am Laufen halten (`systemd`, Autostart);
  Authentifizierung muss über einen Proxy ergänzt werden.
* **Geeignet für:** den Regelbetrieb einer Wache.

## D – WebDAV / Netzlaufwerk als Ablage, Polling durch die Anwendung

* **Aufwand:** gering, wenn ein WebDAV-Endpunkt existiert.
* **Dafür:** kein eigener Dienst, vorhandene Rechtevergabe.
* **Dagegen:** Sperrverhalten je Server unterschiedlich; verlorene Schreibvorgänge
  sind wahrscheinlicher, weil nur ganze Dateien und nicht Felder zusammengeführt
  werden können.
* **Geeignet für:** wenn kein eigener Prozess betrieben werden darf.

## E – Backend-as-a-Service (Supabase, Firebase, PocketBase)

* **Aufwand:** 1–2 Stunden. PocketBase ist eine einzelne Binärdatei und wäre die
  naheliegendste Wahl dieser Gruppe (Realtime, Benutzerverwaltung, Admin-Oberfläche
  ohne eigenen Code).
* **Dafür:** Anmeldung, Rollen, Realtime und Backup sind fertig vorhanden.
* **Dagegen:** zusätzliche Software im Netz; Cloud-Varianten (Supabase, Firebase)
  scheiden für Polizeidaten faktisch aus.
* **Geeignet für:** wenn Benutzerverwaltung und Auditierung formal gefordert sind.

## F – Google Sheets / Microsoft 365 als Speicher

* **Aufwand:** mittel (API-Zugang, OAuth).
* **Dafür:** vertraute Oberfläche für Auswertungen.
* **Dagegen:** externe Datenhaltung; genau die Tabellenlogik, die abgelöst werden soll.
* **Geeignet für:** nicht für diesen Anwendungsfall.

## Empfehlung

**A für den Pilotbetrieb, C für den Regelbetrieb.** Der Wechsel von A nach C ist
ein Häkchen in den Einstellungen – das Datenformat ist identisch, die lokal
angefallenen Änderungen werden beim ersten Sync hochgeschoben. Wenn später eine
formale Benutzerverwaltung gefordert wird, ersetzt E den Server, ohne dass die
Oberfläche angefasst werden muss: auszutauschen ist allein das Objekt `Sync`
in `wachkladde.html` (rund 40 Zeilen).
