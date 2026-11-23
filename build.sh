#!/bin/sh
# Render the handout to PDF and HTML from the single Typst source.
set -e
cd "$(dirname "$0")"
mkdir -p out
typst compile main.typ out/mapsa.pdf
typst compile --features html --format html main.typ out/mapsa.html
echo "Wrote out/mapsa.pdf and out/mapsa.html"
