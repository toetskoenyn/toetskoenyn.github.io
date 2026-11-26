#!/bin/sh
# Quarto post-render step. Quarto turns each page into <name>.typ and
# compiles that to <output-dir>/<name>.pdf; this compiles the same .typ
# files to <output-dir>/<name>.html and then removes them, so any .typ left here is from
# the render that just ran.
cd "$QUARTO_PROJECT_DIR" || exit 1
outdir=${QUARTO_PROJECT_OUTPUT_DIR:-docs}
status=0

# The HTML embeds the same font files the PDF uses, as data URIs, so the page
# is self-contained. Rebuild the stylesheet when a font file is newer.
ext=_extensions/tufte
fonts_css="$ext/assets/fonts.css"
if [ ! -f "$fonts_css" ] || [ -n "$(find "$ext/fonts" -name '*.ttf' -newer "$fonts_css")" ]; then
  {
    for style in Regular Italic; do
      [ "$style" = Italic ] && fs=italic || fs=normal
      printf '@font-face { font-family: "EB Garamond"; font-style: %s; font-weight: 400; font-display: block;\n' "$fs"
      printf '  src: url("data:font/ttf;base64,%s") format("truetype"); }\n' "$(base64 < "$ext/fonts/EBGaramond-$style.ttf" | tr -d '\n')"
    done
  } > "$fonts_css"
fi

for typ in *.typ; do
  [ -f "$typ" ] || continue
  html="$outdir/${typ%.typ}.html"
  out=$("${QUARTO_TYPST:-typst}" compile --features html --format html --font-path "$ext/fonts" "$typ" "$html" 2>&1) || {
    echo "$out"
    status=1
    continue
  }
  # Drop Typst's standing "html export is experimental" notice.
  echo "$out" | grep -v -e "html export is under active development" -e "hint:" -e '^$' || true
  echo "Wrote $outdir/${typ%.typ}.html"
  rm "$typ"
done
exit $status
