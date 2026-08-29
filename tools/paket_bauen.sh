#!/bin/sh
# Erzeugt/aktualisiert den fertigen Netzordner aus der Quelldatei.
set -e
cd "$(dirname "$0")/.."
cp wachkladde.html netzordner/Wachkladde.html
mkdir -p netzordner/daten/ops netzordner/daten/presence netzordner/server
cp server/wachkladde-server.ps1 "server/Wachkladde-Server starten.cmd" \
   server/rechte.json server/server.js netzordner/server/
cp docs/BETRIEB.md netzordner/BETRIEB.md
echo "netzordner/ aktualisiert – Ordner auf das Netzlaufwerk kopieren."
