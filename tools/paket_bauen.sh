#!/bin/sh
# Erzeugt/aktualisiert den fertigen Netzordner aus der Quelldatei.
set -e
cd "$(dirname "$0")/.."
cp wachkladde.html netzordner/Wachkladde.html
mkdir -p netzordner/daten/ops netzordner/daten/presence
echo "netzordner/ aktualisiert – Ordner auf das Netzlaufwerk kopieren."
