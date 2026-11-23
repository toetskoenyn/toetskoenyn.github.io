#!/bin/sh
# Quarto pre-render step: stop early unless Quarto is using Typst 0.15 or
# later. Quarto 1.7 bundles Typst 0.13, which has no HTML export, so
# _environment must point QUARTO_TYPST at a newer system Typst.
need=0.15
typst=${QUARTO_TYPST:-}
if [ -z "$typst" ]; then
  echo "QUARTO_TYPST is not set; Quarto would use its bundled Typst." >&2
  echo "Set it in _environment to a Typst $need+ binary." >&2
  exit 1
fi
ver=$("$typst" --version 2>/dev/null | awk '{print $2}')
if [ -z "$ver" ]; then
  echo "Cannot run $typst (from QUARTO_TYPST in _environment)." >&2
  exit 1
fi
lowest=$(printf '%s\n%s\n' "$need" "$ver" | sort -t. -k1,1n -k2,2n -k3,3n | head -n1)
if [ "$lowest" != "$need" ]; then
  echo "Typst $ver at $typst is too old; need $need or later for HTML export." >&2
  exit 1
fi
