// Quarto partial: the look and layout live in tufte.typ.
#import "_extensions/tufte/tufte.typ": *

// Pandoc writes block quotes as #blockquote[...]; route them to the
// handout's quote styling (indented in PDF, <blockquote> in HTML).
#let blockquote(body) = quote(block: true, body)
