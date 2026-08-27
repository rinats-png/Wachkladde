# Betrieb über einen gemeinsamen Netzwerkordner

## Was dahintersteckt

Ein Browser darf normalerweise nicht auf das Dateisystem schreiben. Chrome und Edge
kennen dafür seit Version 86 die **File System Access API**: die Anwendung bittet
einmal um einen Ordner, der Benutzer wählt ihn aus, und ab dann darf genau dieser
Ordner gelesen und beschrieben werden – sonst nichts. Das funktioniert auch, wenn
die Seite direkt per Doppelklick aus dem Explorer geöffnet wird (`file://`).

Damit braucht es keinen Server, keine Installation und keine Datenbank.

## Die Regel, die alle Konflikte verhindert

> **Jeder Arbeitsplatz schreibt ausschließlich in seine eigenen Dateien.
> Gelesen wird alles.**

Damit kann es auf SMB-Ebene keine konkurrierenden Schreibzugriffe geben – das
Problem, an dem die gemeinsame Nutzung einer `.xlsm` scheitert, entsteht gar nicht
erst.

```
Wachkladde\
    Wachkladde.html
    ANLEITUNG.txt
    daten\
        snapshot.json              gemeinsamer Stand (von einem Platz beim Aufräumen geschrieben)
        ops\
            pc-a3f91c.jsonl        Änderungen dieses Arbeitsplatzes – nur er schreibt sie
            pc-77b2e0.jsonl        Änderungen des nächsten Arbeitsplatzes
        presence\
            pc-a3f91c.json         "wer ist gerade online, an welchem Tag"
```

## Ablauf

**Alle 5 Sekunden** (einstellbar) macht jeder Arbeitsplatz zwei Dinge:

1. **Senden** – die eigenen offenen Änderungen an die eigene `ops`-Datei anhängen.
   Jede Änderung ist eine Zeile:

   ```json
   {"id":"op_k3f9a1","path":"tage.2026-08-08.TD.einteilungen.b_7f3a91.abwesenheit",
    "val":"Krank","ts":1786550400000,"by":"Schäfer"}
   ```

2. **Holen** – alle fremden `ops`-Dateien prüfen. Nur die tatsächlich geänderten
   werden gelesen (Vergleich über den Änderungszeitstempel der Datei), und davon
   nur die noch nicht verarbeiteten Zeilen.

**Zusammengeführt wird feldgenau.** Für jeden Feldpfad merkt sich der Arbeitsplatz,
wann er ihn zuletzt gesetzt hat. Eine fremde Änderung mit jüngerem Zeitstempel wird
übernommen, eine ältere verworfen. Weil die Einheit ein einzelnes Feld ist –
nicht die Datei, nicht der Tag, nicht einmal die Zeile – stören sich Tagdienst und
Nachtdienst praktisch nie. Echte Kollisionen entstehen nur, wenn zwei Personen
dasselbe Feld anfassen. Dann erscheint bei beiden ein Hinweis:

> **Übernommen:** tage.2026-08-08.TD.dglAn — geändert von **Schäfer** → „Krug"

Das ist der wesentliche Unterschied zum Tabellenblatt: es wird nichts still
entschieden.

**Anwesenheit.** Alle 30 Sekunden schreibt jeder Platz eine kleine Datei nach
`presence\` mit Namen, Uhrzeit und aktuell geöffnetem Tag. Oben rechts steht
dann „2 weitere online", in den Einstellungen mit Namen.

## Aufräumen

Die `ops`-Dateien wachsen mit jeder Änderung. *Einstellungen → Ordner aufräumen*
faltet alles in eine frische `snapshot.json` und leert die eigene `ops`-Datei.
Im Snapshot steht zusätzlich, wie viele Zeilen jedes Arbeitsplatzes bereits
enthalten sind; jeder andere Platz kürzt daraufhin beim nächsten Abgleich seine
eigene Datei selbst. Es geht dabei nichts verloren – auch nicht für einen Platz,
der währenddessen ausgeschaltet war. Praktisch: einmal im Monat, etwa beim
Monatswechsel.

## Grenzen – ehrlich benannt

| Punkt | Bedeutung |
|---|---|
| **Chrome oder Edge nötig.** Firefox und Safari können die API nicht. | Auf Windows-Arbeitsplätzen mit Edge unkritisch. Andere Browser zeigen einen Hinweis und laufen im Einzelplatzbetrieb weiter. |
| **Ordnerfreigabe einmal je Arbeitsplatz bestätigen.** Bei Öffnen per `file://` kann der Browser die Berechtigung nicht immer dauerhaft merken. | Im schlechtesten Fall ein Klick beim ersten Öffnen am Tag. |
| **Abgleich alle paar Sekunden, nicht sofort.** | Für eine Kladde ohne Bedeutung; wer sofort sehen will, drückt „Jetzt synchronisieren". |
| **Die Uhren der Arbeitsplätze entscheiden bei Kollisionen.** | In einer Domäne sind sie über NTP gleich. Der Konflikthinweis nennt immer den Namen, sodass Abweichungen auffallen. |
| **Wer den Ordner schreiben darf, darf alles ändern.** Die Rollen in der Anwendung sind eine Bedienhilfe. | Zugriffskontrolle ist die NTFS-Berechtigung der Freigabe – wie heute bei der `.xlsm` auch. Wird mehr verlangt, ist Variante C mit Server und Reverse Proxy der Weg. |
| **Kein Löschschutz.** Wer den Ordner löschen darf, löscht die Kladde. | Laufwerks-Backup wie bisher; zusätzlich wöchentlich *JSON exportieren*. |

## Nachweisbarkeit

`daten\ops\*.jsonl` ist ein reines Anhäng-Protokoll: jede einzelne Änderung mit
Feldpfad, altem Ziel, neuem Wert, Zeitstempel und Namen. Für eine Kladde, die als
Nachweis dienen soll, ist das mehr, als die Excel-Datei je geliefert hat – dort war
nach dem Überschreiben einer Zelle nichts mehr zu sehen. Diese Dateien sollten
deshalb nicht rotiert, sondern beim Aufräumen archiviert werden.
