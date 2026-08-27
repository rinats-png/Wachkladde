# Gestaltung

## Warum nicht wie Excel

Der erste Entwurf hat die Tabelle nachgebaut — dieselben Spalten, dieselben Kästchen.
Das ist der naheliegende, aber falsche Weg: die Rasterdarstellung war nie eine
Entscheidung für die Kladde, sondern das, was Excel eben kann. Wer als DGL um 05:30 Uhr
wissen will, wie es um die Besetzung steht, liest keine Zellen, sondern sucht ein Signal.

Die Oberfläche ist deshalb als **Schichtkonsole** angelegt und nicht als Formular.

## Aussage

**Dienststelle bei Tageslicht.** Warmes Papierweiß, ruhige Graustufen, kräftige
Signalfarben nur dort, wo sie etwas bedeuten. Ruhig genug für zwölf Stunden
Bildschirm, deutlich genug für einen Blick im Vorbeigehen — und nah genug am
Ausdruck, dass Bildschirm und Papier zusammengehören.

## Schrift

| Zweck | Schrift | Grund |
|---|---|---|
| Beschriftungen, Titel | **Bahnschrift** | Die Windows-Umsetzung der DIN 1451 — dieselbe Schrift wie auf Verkehrs- und Behördenschildern. Auf jedem Windows 10/11 vorhanden, kein Download, keine Internetverbindung nötig. Als variable Schrift auf `wdth 75–87` verschmälert, das gibt den technischen Ton. |
| Fließtext | Segoe UI Variable | Auf Windows die lesbarste Vorgabe, unauffällig. |
| Kennungen, Zahlen | Cascadia Mono / Consolas | `19/12`, `1:3 Bea.`, Bestandsangaben und die Ist-Spalte stehen dimensionsstabil untereinander. |

Fallback-Ketten sind gesetzt; unter Linux oder macOS greift die jeweils nächstbeste
Schrift, ohne dass das Layout springt.

## Farbe trägt Bedeutung

Farbe ist hier kein Schmuck, sondern die schnellste Informationsschicht. **Jeder
Listeneintrag** — jede Abwesenheit, jede Einteilung, jede Abstellungsart — trägt
seine eigene Farbe, frei zuweisbar in den Einstellungen.

Die Palette hat **24 Töne**, bewusst alle in ähnlicher Helligkeit gehalten: dunkel
genug, um als Text auf einer hellen Tönung derselben Farbe zu stehen. Genau das
macht die Plakette aus — heller Grund, kräftige Schrift, dünne Kontur, alles aus
einem Farbwert abgeleitet. Wer einen eigenen Farbwert braucht, bekommt ihn.

Vorbelegt ist eine Systematik, die man nicht lernen muss, sondern sieht:

| Familie | Vorbelegt für |
|---|---|
| Rot / Rosé | Krank, VD — alles, was die Besetzung ungeplant trifft |
| Violett / Purpur | Urlaub, Elternzeit — geplante Abwesenheit |
| Bernstein / Ziegel | Sondereinsatz, Terminal 3, Flex |
| Blau / Cyan | Lehrgang, Abordnung, Hospitation, BA |
| Grün / Smaragd | Wache, Tag- und Nachtdienst |
| Grau / Taupe | Dienstfrei, LAK, Teilzeit — planmäßig nicht im Dienst |

Ungeplante Ausfälle und genehmigter Urlaub sehen damit verschieden aus, ohne dass
jemand die Spalte lesen muss. Die Zuordnung liegt in den Stammdaten und gilt
deshalb für alle Arbeitsplätze gleich.

## Die Wachstärke als Ampel

Zwei Anzeigen im Kartenkopf beantworten die Frage, für die es die Kladde gibt:
**reicht die Besetzung?** „Wache 8 / 5" grün heißt erfüllt, rot heißt unterschritten
— dann pulst die Zahl langsam, damit es auffällt, ohne zu blinken.

Gezählt werden Stammbesetzung und Ergänzungsdienst gemeinsam; beide stehen an
diesem Tag auf dieser Wache. Welche Gründe die Stärke reduzieren (Urlaub, krank,
dienstfrei, Lehrgang, Abordnung, BSOD …) und welche als Besetzung des Terminal 3
zählen, entscheidet die Dienststelle selbst in den Einstellungen — die Regel gehört
in die Wache, nicht in den Programmcode. Die geforderte Stärke ist für Tag- und
Nachtdienst getrennt einstellbar; eine 0 schaltet die Prüfung ab.

Auf dem Ausdruck bleibt die Aussage erhalten, ohne Farbe: eine unterschrittene
Stärke bekommt den Zusatz „unterschritten".

## Die Bausteine

**Tagesleiste** statt Datumsfeld. Sieben Tage nebeneinander, jeder mit seinen beiden
Dienstgruppen als Kürzel (`T5 N4`). Der Dienstplan der kommenden Woche ist damit
sichtbar, ohne irgendwo hinzuklicken. Wochenendtage sind rot beschriftet.
Pfeiltasten links/rechts blättern, `t` springt auf heute.

**Besetzungsanzeige** statt Zählspalte. Ein Segment je Beamter, gefüllt = im Dienst,
rot = fehlt. „6 / 14 im Dienst" steht daneben, aber das Bild ist schneller.

**Übergroße Dienstgruppennummer** als Konturziffer im Kartenkopf — wie eine
Gerätekennzeichnung. Sie beantwortet die häufigste Frage („welche DG ist das?") aus
drei Metern Entfernung.

**Signalplaketten** statt Auswahlfelder. Abwesenheit und Einteilung sind gefärbte
Pillen, die Einteilung zusätzlich in Monospace. Beides sind echte `<select>`-Elemente:
mit Tastatur bedienbar, ohne Bibliothek, nur ohne den Formularkasten drumherum.

**Abstellungsblöcke** tragen eine farbige Kante und einen Farbtupfer im Titel. Der
erste Block ist für die **Wache Terminal 3** vorgesehen und hat dafür eigene
Feldnamen; die Grundfarbe je Blockart steht in den Einstellungen, einzelne Blöcke
lassen sich davon abweichend färben — etwa um eine Lage über mehrere Tage
wiederzuerkennen.

**Fehlende Beamte** dimmen ab, bekommen eine farbige Kante links und einen sanften
Farbverlauf über die Zeile. Anwesende bleiben kräftig. Der Blick landet zuerst auf dem,
was da ist.

## Was bewusst eine Tabelle geblieben ist

Die Dienstliste ist weiterhin ein `<table>`. Das ist die richtige Auszeichnung für
tabellarische Daten — für Screenreader, für die Tastatur und für den Ausdruck. Nach
Tabellenblatt aussehen tut sie trotzdem nicht: keine senkrechten Linien, keine
Zellkästen, großzügige Zeilenhöhe, Kopfzeile als Kleinschrift-Beschriftung. Der
Excel-Eindruck kam von umrandeten Zellen, nicht vom Tabellenelement.

## Der Ausdruck bleibt Papier

Auf dem Bildschirm eine Konsole, auf dem Papier ein Vordruck. Der Druckmodus schaltet
auf Weiß, zieht Haarlinien, blendet alles Bedienbare aus — und ersetzt jedes
Eingabefeld durch den Wert als Fließtext. Das ist der Grund, warum lange Bemerkungen
im Ausdruck vollständig stehen, während sie im Feld abgeschnitten wären.
Leergebliebene Zeilen behalten ihre Höhe, damit von Hand ergänzt werden kann.

Eine Seite je Schicht, A4 hochkant. Für sehr volle Tage gibt es „kompakt drucken".
Zum Vergleich: die Excel-Vorlage druckte auf 49 % skaliert.

## Bewegung

Zurückhaltend und einmalig: Schichtkarten fahren beim Tageswechsel gestaffelt ein,
der Verbindungspunkt pulst, Tageschips heben sich beim Überfahren leicht an. Kein
Effekt, der beim zwanzigsten Tageswechsel noch auffällt — genau das ist die Absicht.
Die einzige Ausnahme ist die unterschrittene Wachstärke: sie darf auffallen.

## Eine Ansicht, nicht zwei

Es gab zwischenzeitlich einen Dunkelmodus. Er ist wieder entfernt. Zwei Farbwelten
zu pflegen kostet bei jeder Änderung doppelt, und die Kladde wird ausgedruckt und
unterschrieben — der Bildschirm sollte aussehen wie das, was hinterher aus dem
Drucker kommt.
