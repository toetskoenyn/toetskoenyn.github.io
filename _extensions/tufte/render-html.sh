#!/bin/sh
# Quarto post-render step. Quarto turns each page into <name>.typ and
# compiles that to out/<name>.pdf; this compiles the same .typ files to
# out/<name>.html and then removes them, so any .typ left here is from
# the render that just ran.
cd "$QUARTO_PROJECT_DIR" || exit 1
outdir=${QUARTO_PROJECT_OUTPUT_DIR:-out}
status=0
for typ in *.typ; do
  [ -f "$typ" ] || continue
  html="$outdir/${typ%.typ}.html"
  out=$("${QUARTO_TYPST:-typst}" compile --features html --format html "$typ" "$html" 2>&1) || {
    echo "$out"
    status=1
    continue
  }
  # Drop Typst's standing "html export is experimental" notice.
  echo "$out" | grep -v -e "html export is under active development" -e "hint:" -e '^$' || true
  echo "Wrote out/${typ%.typ}.html"
  rm "$typ"
done
exit $status
