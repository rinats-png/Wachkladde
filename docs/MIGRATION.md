# Migration von der Excel-Kladde zur HTML-Anwendung

## 1. Befund: Was die Excel-Datei heute tut

`Wachkladde_08_August_2026.xlsm`, 35 Blätter:

| Blatt | Rolle |
|---|---|
| `EingabeSchicht` (versteckt) | Stammdaten: 5 Dienstgruppen × bis zu 16 Beamte, Amtsbezeichnungen, Anfangsdatum (`H2`), Rotationstabellen, alle Dropdown-Listen |
| `01` … `30`, `31 oder 01 Folgemonat` | ein Blatt je Kalendertag, darin **zwei** Schichten: Tagdienst in Spalten A–K, Nachtdienst in M–W (identischer Aufbau, um 12 Spalten versetzt) |
| `Tabelle1`, `Tabelle2`, `Tabelle4` (versteckt) | leer |

Aufbau eines Tagesblatts (TD-Block, ND-Block = +12 Spalten):

```
Zeile 1      Revier | Dienstgruppe (K1, per VLOOKUP aus dem Vortag)
Zeile 3      "Wachdienstplan für" | Datum (=Vortag+1) | TD/ND
Zeile 4      Einsatzzug (Dropdown)
Zeile 6–21   Nr | Name (VLOOKUP) | Amtsbez. (VLOOKUP) | Zählhilfe | Abwesenheit
             (Dropdown) | Ist (Laufsumme) | Einteilung (Dropdown) | Bemerkung
Zeile 22–29  Ergänzungsdienst (verstärkende DG, Namen von Hand)
Spalte I/J   Abstellungen/BSOD, 4 Blöcke (Anlass/Beamte/Name/MOZ/Dienstanz./bes. FEM)
Zeile 30–36  Lehrgänge / Gerichtstermine
Zeile 37–44  Sonstiges
Zeile 45–55  Bestandsübergabe (Verwarngelder, Asservate, Token, Haftbefehle …)
Zeile 56     übergebender / übernehmender DGL
```

Die Rotation ist **keine Wochentagslogik**, sondern eine Kette über die DG-Nummer:

```
TD(morgen)    = nextTag[TD(heute)]            EingabeSchicht!Q47:R51   1→2→4→5→3→1
ND(heute)     = nachtVonTag[TD(heute)]        EingabeSchicht!K47:L51
Verst. TD     = verstVonTag[TD(heute)]        EingabeSchicht!Z47:AA51
Verst. ND     = verstNachtVonVerst[Verst.TD]  EingabeSchicht!W47:X51
```

## 2. Gefundene Schwachstellen

| # | Befund | Auswirkung | Lösung in der HTML-Fassung |
|---|---|---|---|
| 1 | **Kette bricht bei überschriebenen Formeln.** Auf Blatt `01` steht in `M23` die Zahl `2` statt der Formel, auf `30` in `A23`/`M23` feste Zahlen, auf `31` in `A23`. Der Nachrechner ergibt dort andere Werte. | Stille Fehlplanung – niemand sieht, dass eine Formel weg ist. | Rotation wird berechnet; eine Abweichung wird als `≠ Plan n ↺` sichtbar markiert und ist bewusst setzbar. |
| 2 | **Falsche Blattreferenz.** `07!K1` verweist auf `'01'!K1` statt `'06'!K1`. Aktuell fällt es nicht auf, weil beide Blätter zufällig DG 2 führen. | Bei jeder Verschiebung des Monatsanfangs kippt der ganze Rest des Monats. | Kein Blattkettenbezug mehr – ein Anfangsdatum + eine Anfangs-DG. |
| 3 | **Ein Blatt pro Tag, ein Workbook pro Monat.** 31 nahezu identische Kopien; jede Layoutänderung muss 31-mal nachgezogen werden. | Wartungsaufwand, Layout-Drift (Blatt `01` und `05` haben tatsächlich abweichende Zeilenpositionen). | Ein Layout, Daten getrennt davon; beliebig viele Tage. |
| 4 | **Daten und Darstellung vermischt.** Der Name steht nicht als Datum, sondern als `VLOOKUP("2-7")`-Ergebnis in einer Zelle. Auswertungen über den Monat sind praktisch unmöglich. | Kein Krankenstand, keine Abstellungsstatistik, kein Suchen. | Normalisiertes JSON, Beamte über stabile IDs referenziert. |
| 5 | **Nummerierung ist starr.** Genau 16 Zeilen; ein 17. Beamter passt nicht, gelöschte Beamte hinterlassen Lücken bzw. `#NV`. | Stammdatenpflege ist Handarbeit im geschützten Blatt. | Beamte je DG frei hinzufügbar/sortierbar/deaktivierbar, Nummerierung immer lückenlos 1…n. |
| 6 | **Hilfsspalten im Nutzblatt** (`D`/`P` „Zählt wenn ja", `F4 =D6*D6` als Rest). Die „Ist"-Summe hängt an Textvergleichen (`"0"`/`"1"` als Text). | Fragil, für Nutzer unverständlich. | „Ist" wird zur Anzeigezeit berechnet, nichts wird gespeichert. |
| 7 | **Kein Mehrbenutzerbetrieb.** `.xlsm` auf einem Laufwerk lässt sich nur exklusiv öffnen; VBA verhindert Co-Authoring. | TD und ND können nicht gleichzeitig schreiben. | Feldgenaue Synchronisation, mehrere Arbeitsplätze gleichzeitig. |
| 8 | **Kein Änderungsnachweis.** Wer hat wann die Abwesenheit geändert? | In einer Dienstkladde ein echtes Problem. | Jede Änderung wird als Op (`Pfad, Wert, Zeit, Benutzer`) protokolliert. |
| 9 | **Druck bei 49 % Skalierung.** Portrait A4, zwei Druckbereiche. | Kaum lesbar, Ausdrucke werden handschriftlich ergänzt. | Eigenes Druck-Stylesheet, eine Seite je Schicht, Modus „kompakt". |
| 10 | **Blattschutz + Makros.** SHA-512-Schutz je Blatt, 70 KB `vbaProject.bin`; Makro-Warnung bei jedem Öffnen. | Niemand außer dem Ersteller kann etwas ändern; Sicherheitsrichtlinien blockieren Makros. | Kein Makro, keine Sperre; Rechte über Rollen. |
| 11 | **Validierungslisten liegen im versteckten Blatt** und sind nicht ohne Aufheben des Schutzes pflegbar. | Neue Einteilungen (`19/xx`) landen als Freitext. | Listen in den Stammdaten pflegbar. |
| 12 | **Freitext statt Struktur** bei Abstellungen („1:2 Bea. D 219 (davon 1:1 TD)"). | Nicht auswertbar. | Blöcke mit benannten Feldern; Feldnamen je Blocktyp konfigurierbar. |

## 3. Datenschema

```jsonc
{
  "schemaVersion": 1,
  "meta":   { "revier": "19. Polizeirevier", "titel": "Wachdienstplan für" },
  "settings": {
    "user": "Schäfer", "rolle": "dgl",            // admin | dgl | beamter | leser
    "syncMode": "rest", "syncUrl": "http://wache-srv:8080", "syncInt": 10,
    "colors": { "--c-accent": "#1b4b8f", "...": "..." },
    "datum": "2026-08-08", "kompakt": false
  },
  "stammdaten": {
    "dienstgruppen": [
      { "id": "dg_a1b2c3", "nr": 1, "name": "DG 1",
        "beamte": [
          { "id": "b_7f3a91", "name": "Holtschke", "amtsbez": "NIT",
            "rolle": "beamter", "aktiv": true,     // Nummer NICHT gespeichert –
            "aktivVon": "2026-09-01",              // sie ergibt sich fortlaufend
            "aktivBis": "2026-08-31" }             // Gültigkeit: für Versetzungen
        ] }
    ],
    "listen": { "abwesenheit": [], "einteilung": [], "einsatzzug": [], "bestand": [] },
    "abstVorlagen": [
      { "titel": "Wache Terminal 3", "farbe": "#c2410c",
        "felder": ["Anlass","Beamte","L- Wache","Wache","Streife"] },
      { "titel": "Abstellung / BSOD", "farbe": "#b45309",
        "felder": ["Anlass","Bea.","Name","MOZ","Dienstanz.","bes. FEM"] }
    ],
    "farben": {                       // Signalfarbe je Listeneintrag
      "Krank": "#b3261e", "Urlaub genehmigt": "#6d28d9", "DGL": "#1d4ed8", "…": "…"
    },
    "wachstaerke": {                          // Schlüssel 0=So … 6=Sa (JS-Wochentag)
      "regulaer": { "TD": {"1":5,"2":5,"…":0}, "ND": {"1":4,"…":0} },
      "terminal": { "TD": {"1":3,"…":0},       "ND": {"1":3,"…":0} },
      "reduziert":       ["Krank","Urlaub genehmigt","Dienstfrei","Lehrgang","…"],
      "terminalGruende": ["Terminal 3"]
    }
  },
  "rotation": {
    "startDatum": "2026-08-01", "startDgTag": 2,
    "nextTag":            { "1":2, "2":4, "4":5, "5":3, "3":1 },
    "nachtVonTag":        { "1":3, "2":1, "4":2, "3":5, "5":4 },
    "verstVonTag":        { "1":2, "2":4, "4":5, "5":3, "3":1 },
    "verstNachtVonVerst": { "1":4, "2":5, "4":3, "5":1, "3":2 }
  },
  "abgeschlossen": {                        // Monatsabschluss – sperrt die Tage
    "2026-08": { "ts": 1787839594433, "by": "Schäfer", "tage": 31 }
  },
  "tage": {
    "2026-08-08": {
      "TD": {
        "datum": "2026-08-08", "schicht": "TD", "dgNr": 5, "einsatzzug": "",
        "einteilungen": {
          "b_7f3a91": { "abwesenheit": "Krank", "einteilung": "", "bemerkung": "05:30 Krankmeldung",
                        "von": "05:30", "bis": "",
                        "folge": [ { "von": "12:00", "bis": "", "abwesenheit": "Terminal 3",
                                     "einteilung": "", "bemerkung": "" } ] }
        },
        "ergaenzung": { "dgNr": 3, "eintraege": [ { "name": "Fink", "abwesenheit": "Terminal 3",
                                                    "einteilung": "", "bemerkung": "" } ] },
        "abstellungen": [ { "vorlage": 0, "werte": { "Anlass": "Terminal 3 Frühdienst" } } ],
        "lehrgaenge":  [ { "name": "", "art": "", "ort": "", "zeit": "", "eintrag": "" } ],
        "sonstiges": "",
        "bestand": { "Verwarngeld D219 - bar": "170", "Asservate - StPO": "7x" },
        "dglAb": "", "dglAn": ""
      },
      "ND": { "…": "…" }
    }
  },
  "_cursor": 0        // Stand des zuletzt geholten Server-Op-Logs
}
```

Zwei Entscheidungen sind wichtig:

* **Beamte werden über `id` referenziert, nicht über den Namen.** Eine Namensänderung
  („Haas, A." → „Haas-Meier, A.") verändert damit keine historischen Tage.
* **Eine Versetzung erzeugt einen zweiten Eintrag, kein Umhängen.** Der bisherige
  Eintrag bekommt `aktivBis`, in der Zieldienstgruppe entsteht ein neuer mit
  `aktivVon` und eigener `id`. Bereits erfasste Tage zeigen weiter auf die alte
  `id` und bleiben damit unverändert richtig — genau das wäre beim Verschieben
  eines Eintrags verlorengegangen.
* **Die Wachstärke rechnet mit dem Hauptstatus einer Zeile.** Folgeeinträge und
  Zeiträume dokumentieren den Verlauf, verändern die Zählung aber nicht; sonst
  wäre nicht mehr nachvollziehbar, welche Zahl im Kopf steht.
* **Farben und Wachstärke liegen in den Stammdaten, nicht in den Einstellungen.**
  Sie sind eine Festlegung der Dienststelle und gelten deshalb für alle
  Arbeitsplätze; die Einstellungen enthalten nur, was den einzelnen Rechner
  betrifft (Name, Rolle, Ordner, Druckdichte).
* **Die laufende Nummer wird nicht gespeichert.** Sie ist eine Funktion der
  Reihenfolge der aktiven Beamten: `nr = Position in [b for b in beamte if b.aktiv]`.
  Deshalb ist sie nach jedem Hinzufügen, Verschieben oder Deaktivieren automatisch
  wieder lückenlos.

## 3a. Automatische Anpassung älterer Stände

Beim Laden — auch beim Einlesen einer Sicherung und beim ersten Ordnerabgleich —
zieht `Store.migrieren()` ältere Stände still nach:

* fehlende `farben` und `wachstaerke` werden mit den Vorgaben aufgefüllt;
* eine `wachstaerke`, die je Schicht noch **eine** Zahl enthielt, wird auf alle
  sieben Wochentage verteilt;
* die Einteilung `DGL- EZF` (mit dem Leerzeichen aus dem Tabellenblatt) wird zu
  `DGL-EZF` — in der Liste **und** in allen bereits erfassten Tagen;
* `DGL`, `V-DGL`, `DGL-EZF`, `V-DGL-EZF` stehen danach in dieser Reihenfolge am
  Anfang der Einteilungsliste;
* der erste Abstellungsblock heißt `Wache Terminal 3`.

Die Migration schreibt keine Ops. Jeder Arbeitsplatz kommt für sich zum selben
Ergebnis, es entsteht also kein Abgleichsverkehr und kein Konflikt.

## 3b. Monatsabschluss

*Auswertung → Monat abschließen* legt zwei Dateien in `<Ordner>/archiv/<Monat>/`:

| Datei | Inhalt |
|---|---|
| `wachkladde-2026-08.json` | Stammdaten, Rotation und alle Tage des Monats — vollständig wieder einlesbar |
| `wachkladde-2026-08.html` | eigenständige, druckfertige Fassung ohne Bedienelemente; öffnet sich in jedem Browser, auch in zehn Jahren |

Anschließend wird der Ordner verdichtet und der Monat in `abgeschlossen` vermerkt.
`Store.apply()` verweigert danach jede Änderung an Tagen dieses Monats — die
Sperre sitzt also im Datenzugriff, nicht nur in der Oberfläche. Admin und DGL
können über das Hinweisband oder die Auswertung wieder entsperren; das Archiv
bleibt dabei unberührt.

Ist kein Ordner verbunden, werden beide Dateien stattdessen heruntergeladen.

## 4. Persistenz und Synchronisation

**Lokal.** Der gesamte Zustand liegt unter `localStorage["wachkladde.v1"]`; zusätzlich
`…v1.ops` (noch nicht gesendete Änderungen) und `…v1.meta` (Zeitstempel je Feldpfad).
Geschrieben wird gebündelt 150 ms nach der letzten Eingabe. Mehrere Tabs desselben
Rechners halten sich über `BroadcastChannel` sofort synchron.

**Netzwerk.** Jede Änderung erzeugt eine Op:

```json
{ "id":"op_k3f9a1", "path":"tage.2026-08-08.TD.einteilungen.b_7f3a91.abwesenheit",
  "val":"Krank", "ts":1786550400000, "by":"Schäfer" }
```

Der Client sendet offene Ops an `POST /api/ops` und holt fremde über
`GET /api/ops?since=<cursor>`. Zusammengeführt wird **feldgenau nach Last-Write-Wins**:

* fremde Op **neuer** als der lokale Stand des Feldes → wird übernommen;
  wenn der lokale Wert dabei überschrieben wird, erscheint eine Hinweiszeile
  („Übernommen: … geändert von Schäfer");
* fremde Op **älter** → wird verworfen, Hinweiszeile „Konflikt: Ihre neuere Fassung bleibt".

Weil die Granularität ein einzelnes Feld ist, kollidieren TD und ND praktisch nie;
echte Kollisionen gibt es nur, wenn zwei Personen dieselbe Zelle bearbeiten – und
genau dann wird es angezeigt statt still entschieden.

Der Server ist ein Append-Only-Log (`ops.jsonl`) plus materialisierter Snapshot.
Ops sind über ihre `id` idempotent, ein doppelter Versand ist folgenlos.

## 5. Umstellung in 6 Schritten

1. **Sichern.** Kopie der `.xlsm` in ein Archivverzeichnis (`Archiv/2026-08/`).
2. **Importieren.** `python3 tools/import_xlsm.py Wachkladde_08_August_2026.xlsm > wachkladde.json`.
   Der Importer erkennt die Abschnitte über die Beschriftungen in Spalte A, nicht über
   feste Zeilennummern – die abweichenden Layouts der Blätter `01` und `05` werden
   dadurch mit übernommen.
3. **Prüfen.** Anwendung öffnen, JSON importieren, drei Stichtage gegen den Ausdruck
   aus Excel vergleichen (Anfang, Mitte, Monatsende).
4. **Rotation kontrollieren.** *Stammdaten → Schichtrotation*: Anfangsdatum und
   Anfangs-DG setzen, die 7-Tage-Vorschau gegen den Dienstplan halten.
   Für die drei Tage, an denen in Excel Formeln überschrieben waren (01., 30., 31.),
   die abweichende DG bewusst als Override eintragen – oder korrigieren.
5. **Parallelbetrieb.** Eine Woche beides führen. Danach die `.xlsm` schreibgeschützt
   ins Archiv legen.
6. **Ablösen.** Nur noch die HTML-Fassung; einmal wöchentlich
   *Einstellungen → Daten → JSON exportieren* als Backup auf das Dienstlaufwerk.

## 6. Absicherung im Produktivbetrieb

Der mitgelieferte Server ist bewusst minimal. Für den Dauerbetrieb:

* **Reverse Proxy davor** (nginx/Caddy) mit HTTPS und Basic-Auth oder
  Client-Zertifikaten; der Benutzername aus dem Proxy-Header ersetzt dann das
  frei eingetippte Feld in den Einstellungen.
* **Backup** des Verzeichnisses `server/data/` – `ops.jsonl` ist der vollständige
  Änderungsverlauf und damit zugleich das Revisionsprotokoll.
* **Rollen serverseitig prüfen.** Die Rollenprüfung im Browser ist eine
  Bedienhilfe, keine Zugriffskontrolle. Wenn es rechtlich tragen muss, gehört
  die Prüfung in `commit()` in `server/server.js`.
* **Aufbewahrung.** Für eine Kladde, die als Nachweis dient, sollte das Op-Log
  nicht rotiert werden; monatlich einen signierten Snapshot ablegen.
