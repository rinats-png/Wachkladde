# Betrieb im Dienstnetz — welcher Weg, und wer darf schreiben?

## Warum die reine Ordner-Variante nicht funktioniert

Wird `Wachkladde.html` per Doppelklick geöffnet, läuft sie unter `file://`. Browser
behandeln diesen Ursprung als *opak*: er gehört zu keiner Website und bekommt
deshalb keine dauerhaften Berechtigungen. Der Ordnerzugriff (File System Access API)
ist dort gesperrt — Edge meldet:

> Failed to execute 'showDirectoryPicker' on 'Window': The request is not allowed by
> the user agent or the platform in the current context.

Daran ändert weder ein anderer Ordner noch eine Einstellung etwas. Die Seite muss
über **http://** ausgeliefert werden. Sobald das der Fall ist, braucht es die
Ordner-API aber gar nicht mehr — dann übernimmt der Server den Abgleich, und die
Kladde läuft in **jedem** Browser, auch in Firefox.

## Der empfohlene Weg: ein Rechner der Wache stellt sie bereit

Ein beliebiger Windows-Rechner, der ohnehin durchläuft (der Wachrechner selbst
genügt), startet den mitgelieferten Server. Es wird **nichts installiert** — das
Skript nutzt den in Windows eingebauten `HttpListener`.

```
\\<Server>\<Freigabe>\Wachkladde\
    Wachkladde.html
    server\
        Wachkladde-Server starten.cmd     <-- Doppelklick auf dem Bereitstellungs-Rechner
        wachkladde-server.ps1
        rechte.json                       <-- wer schreiben darf
        data\                             <-- legt der Server selbst an
```

1. Auf dem bereitstellenden Rechner **`Wachkladde-Server starten.cmd`** doppelklicken.
   Das Fenster bleibt offen, solange gearbeitet wird.
2. Alle anderen Arbeitsplätze öffnen **`http://<Rechnername>:8080/`** — ein Lesezeichen
   genügt, es wird nichts kopiert und nichts eingerichtet.

Einmalig durch die IT, damit der Port ohne Administratorrechte geöffnet werden darf:

```
netsh http add urlacl url=http://+:8080/ user=DOMAENE\Dienstkonto
netsh advfirewall firewall add rule name="Wachkladde" dir=in action=allow ^
      protocol=TCP localport=8080
```

Zum Ausprobieren ohne diese Freigabe: `Wachkladde-Server starten.cmd -NurLokal`
— dann ist die Kladde nur auf diesem einen Rechner unter `http://localhost:8080/`
erreichbar.

Soll der Server dauerhaft und ohne angemeldeten Benutzer laufen, richtet die IT ihn
als geplante Aufgabe („Bei Systemstart", „Unabhängig von der Benutzeranmeldung")
oder als Dienst ein.

## DGL und V-DGL schreiben, alle anderen lesen

Da sich jeder Beamte mit seiner eigenen Kennung am Rechner anmeldet, ist das ohne
zusätzliche Anmeldung zu lösen: Windows meldet den angemeldeten Benutzer automatisch
an den Server weiter (integrierte Anmeldung, kein Kennwort, kein Login-Fenster).

**Die Prüfung sitzt auf dem Server**, nicht im Browser. Wer nicht schreiben darf,
kann es auch nicht — auch nicht über die Entwicklerwerkzeuge. Und weil der Server
auch die Rolle vorgibt, kann sich niemand in den Einstellungen selbst zum DGL
machen: Name und Rolle sind dort gesperrt, sobald Rechte hinterlegt sind.

Gesteuert wird das in `server\rechte.json`. Zwei Wege, beide möglich:

### Weg 1 — über eine AD-Gruppe (empfohlen)

Der Planerbereich legt eine Gruppe an, z. B. `Wachkladde-Schreiben`, und nimmt die
DGL und V-DGL hinein. Danach ist die Kladde nie wieder anzufassen — wer neu DGL
wird, kommt in die Gruppe, und fertig.

```json
{
  "offen": false,
  "gruppe": "POLIZEI\\Wachkladde-Schreiben",
  "zuordnung": { "schaefer": "Schäfer", "holtschke": "Holtschke" }
}
```

### Weg 2 — einzelne Kennungen

Wenn keine Gruppe eingerichtet werden soll:

```json
{
  "offen": false,
  "schreiben": ["schaefer", "holtschke", "wagner"],
  "zuordnung": { "schaefer": "Schäfer", "holtschke": "Holtschke" }
}
```

### `zuordnung` — Kennung zu Name

Die Anmeldekennung heißt selten wie der Beamte in der Kladde. `zuordnung` verbindet
beides, damit Änderungen unter dem richtigen Namen erscheinen und die Suche greift.
Fehlt ein Eintrag, wird die Kennung selbst verwendet.

### Was der Benutzer merkt

| | schreibberechtigt | nicht berechtigt |
|---|---|---|
| Kladde | normal bedienbar | alle Felder gesperrt |
| Band oben | — | **„Nur Leserechte für …"** |
| Rolle in den Einstellungen | `DGL`, gesperrt | `Leser`, gesperrt |
| Monatsabschluss, Stammdaten | möglich | nicht möglich |

`"offen": true` oder die Datei löschen → jeder darf schreiben. Sind weder `gruppe`
noch `schreiben` gesetzt, sperrt sich niemand aus — das ist Absicht, damit eine
unvollständige Datei nicht die ganze Wache lahmlegt.

Die Datei wird bei **jeder** Anfrage neu gelesen: Änderungen wirken sofort, der
Server muss nicht neu gestartet werden. Verglichen wird der reine Anmeldename ohne
Domäne und ohne Rücksicht auf Groß- und Kleinschreibung — `POLIZEI\Schaefer`,
`schaefer` und `Schaefer` sind dasselbe.

### Hinter einem Reverse Proxy

Läuft statt des PowerShell-Servers der Node-Server hinter einem Proxy, meldet dieser
Benutzer und Gruppen als Kopfzeilen (`X-Remote-User`, `X-Remote-Groups`,
kommagetrennt); die Namen der Kopfzeilen lassen sich in `rechte.json` über
`kopfzeile` und `gruppenKopfzeile` ändern. Wichtig: Der Proxy muss diese Kopfzeilen
aus eingehenden Anfragen **entfernen** und selbst setzen — sonst kann sie jeder
mitschicken.

## Die Rollen in der Anwendung sind etwas anderes

In den Einstellungen gibt es weiterhin DGL / Beamter / Leser. Das ist eine
**Bedienhilfe** — sie verhindert Vertipper, keinen Zugriff. Die verbindliche
Grenze ist die Serverprüfung oben. Beides ergänzt sich: der Server entscheidet, *ob*
jemand schreiben darf, die Rolle entscheidet, *was* ihm angeboten wird.

## Sicherung

Alles liegt in `server\data\`:

| Datei | Inhalt |
|---|---|
| `ops.jsonl` | jede einzelne Änderung mit Feld, Wert, Zeitpunkt und Benutzer — zugleich das Änderungsprotokoll |
| `snapshot.json` | der zusammengefasste Stand |

Dieses Verzeichnis gehört ins normale Laufwerks-Backup. Zusätzlich legt der
Monatsabschluss den fertigen Monat unter `archiv\<Monat>\` als JSON und als
druckfertige HTML ab.

## Ohne Server: Passwortschutz in der Kladde

Lässt sich kein Server einrichten, gibt es den eingebauten Zugriffsschutz —
*Einstellungen → Zugriffsschutz*:

* Ein **Passwort für den Schreibmodus**, das DGL und V-DGL kennen (z. B. `D219`).
  Wer es kennt, trägt ein; alle anderen sehen die Leseansicht.
* Optional ein **zweites Passwort für die Verwaltung**: Dienstgruppen, Wachstärke,
  Farben, Monatsabschluss. So kann der Wachdienst eintragen, ohne die Grundeinstellungen
  verstellen zu können.
* Nach einstellbarer Zeit ohne Änderung **sperrt sich die Kladde von selbst** — auf
  einem Wachrechner läuft ständig jemand vorbei.
* Das Passwort wird **nicht im Klartext** abgelegt, sondern als SHA-256-Hash mit
  Zufallssalz. Wer die Datei im Editor öffnet, liest es dort nicht mit.

Die Freischaltung gilt für die Browsersitzung: nach dem Schließen des Browsers ist
wieder gesperrt.

### Was dieser Schutz leistet — und was nicht

**Er leistet:** dass niemand versehentlich etwas verstellt, dass ein Kollege nicht
„mal eben" in fremden Dienstgruppen herumklickt, und dass die Kladde auf einem
unbeaufsichtigten Rechner nicht offen steht. Für den Alltag einer Wache ist das
genau der Schutz, um den es meistens geht.

**Er leistet nicht:** eine echte Zugriffskontrolle. Die Prüfung läuft im Browser,
und die Daten liegen im Ordner. Wer die HTML-Datei bearbeiten kann oder die
Datendateien direkt öffnet, kommt daran vorbei — kein noch so gutes Passwort ändert
daran etwas, solange die Prüfung auf demselben Rechner läuft wie die Umgehung.

**Beides zusammen ist die richtige Antwort:** der Server entscheidet verbindlich, wer
schreiben *darf*; das Passwort verhindert das versehentliche Ändern und die offene
Sitzung. Ist auf dem Server ein Recht hinterlegt, hat das Vorrang — die Kladde
übernimmt Name und Rolle von dort und lässt sie nicht überschreiben.

## Wenn kein Server erlaubt ist

Bleibt der Einzelplatzbetrieb: `Wachkladde.html` per Doppelklick, alles wird im
Browser gespeichert, Austausch über *Einstellungen → Sicherung schreiben / einlesen*.
Gemeinsames Arbeiten ist so nicht möglich — das ist die ehrliche Auskunft. Der
Passwortschutz oben funktioniert auch hier und ist dann das einzige Mittel.

Die Ordner-Variante bleibt im Programm erhalten und funktioniert, sobald die Seite
über `http://` läuft. Dann ist sie allerdings überflüssig, weil der Server den
Abgleich bereits erledigt.
