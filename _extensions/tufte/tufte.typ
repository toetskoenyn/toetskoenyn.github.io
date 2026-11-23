// tufte.typ: a Tufte handout layout that renders from one source to
// PDF (A4, wide right margin) and to HTML (tufte-css markup).
//
//   typst compile main.typ out/mapsa.pdf
//   typst compile --features html --format html main.typ out/mapsa.html

// ---- Page geometry (PDF) --------------------------------------------------

#let _paper-w = 210mm
#let _left = 24mm
#let _right = 80mm                      // right page margin; holds the margin column
#let _gap = 8mm                         // gutter between text block and margin column
#let _mw = _right - _gap - 16mm         // margin column width
#let _font = ("ETBembo", "Palatino", "Libertinus Serif")

#let _html() = target() == "html"

// ---- Small typographic helpers ---------------------------------------------

// ETBembo has no true small caps, so the PDF fakes them with scaled capitals.
#let sc(body) = context if _html() {
  html.elem("span", attrs: (class: "smallcaps"), body)
} else {
  text(size: 0.82em, tracking: 0.05em, upper(body))
}

// Tufte's small-caps run-in opening for a paragraph.
#let newthought(body) = context if _html() {
  html.elem("span", attrs: (class: "newthought"), body)
} else {
  text(size: 0.82em, tracking: 0.05em, upper(body))
}

// ---- Margin column (PDF) ---------------------------------------------------

// Bottom edge of the last margin item, so notes never overlap: a note that
// would collide with the one above is pushed down beneath it.
#let _margin-bottom = state("tufte-margin-bottom", (page: 0, y: 0pt))

#let _margin-block(body) = block(width: _mw, {
  set text(size: 8.5pt)
  set par(leading: 0.5em, spacing: 0.7em, justify: false)
  body
})

#let _place-margin(body) = context {
  let pos = here().position()
  let content = _margin-block(body)
  let h = measure(content).height
  let prev = _margin-bottom.get()
  // here() sits on the baseline; lift the note so its first line aligns.
  let y = (pos.y - 0.62em).to-absolute()
  if prev.page == pos.page and y < prev.y { y = prev.y }
  _margin-bottom.update((page: pos.page, y: y + h + 7pt))
  box(width: 0pt, height: 0pt, place(
    top + left,
    dx: _paper-w - _right + _gap - pos.x,
    dy: y - pos.y,
    content,
  ))
}

// ---- Notes -----------------------------------------------------------------

#let _sn = counter("tufte-sidenote")
#let _mn = counter("tufte-marginnote")

// Numbered note in the margin.
#let sidenote(body) = {
  _sn.step()
  context {
    let n = str(_sn.get().first())
    if _html() {
      let id = "sn-" + n
      html.elem("label", attrs: ("for": id, class: "margin-toggle sidenote-number"))
      html.elem("input", attrs: (type: "checkbox", id: id, class: "margin-toggle"))
      html.elem("span", attrs: (class: "sidenote"), body)
    } else {
      super(n)
      _place-margin[#super(n)#h(0.2em)#body]
    }
  }
}

// Unnumbered note in the margin.
#let marginnote(body) = {
  _mn.step()
  context {
    if _html() {
      let id = "mn-" + str(_mn.get().first())
      html.elem("label", attrs: ("for": id, class: "margin-toggle"), [⊕])
      html.elem("input", attrs: (type: "checkbox", id: id, class: "margin-toggle"))
      html.elem("span", attrs: (class: "marginnote"), body)
    } else {
      _place-margin(body)
    }
  }
}

// ---- Figures and blocks ----------------------------------------------------

// Main-column grid of images, cropped to a common 3:2 frame, captioned in
// the margin.
#let gridfigure(caption: none, columns: 2, ..images) = context if _html() {
  _mn.step()
  let id = "mn-fig-" + str(_mn.get().first())
  html.elem("figure", {
    html.elem("label", attrs: ("for": id, class: "margin-toggle"), [⊕])
    html.elem("input", attrs: (type: "checkbox", id: id, class: "margin-toggle"))
    html.elem("span", attrs: (class: "marginnote"), caption)
    html.elem("div", attrs: (class: "image-grid"), images.pos().join())
  })
} else {
  let cells = images.pos().map(img => layout(size => box(
    width: 100%,
    height: size.width / columns * 2 / 3,
    clip: true,
    { set image(width: 100%, height: 100%, fit: "cover"); img },
  )))
  block(width: 100%, above: 1.6em, below: 1.6em, breakable: false, {
    grid(columns: (1fr,) * columns, gutter: 2.5mm, ..cells)
    place(top + left, dx: 100% + _gap, _margin-block(caption))
  })
}

// A small-caps label over an italic title, e.g. a recommendation or verdict.
#let callout(label: none, title) = context if _html() {
  html.elem("p", attrs: (class: "callout"), {
    html.elem("span", attrs: (class: "callout-label"), label)
    linebreak()
    html.elem("span", attrs: (class: "callout-title"), title)
  })
} else {
  block(above: 1.6em, below: 1.1em, sticky: true, {
    text(size: 0.82em, tracking: 0.05em, upper(label))
    linebreak()
    text(size: 15pt, style: "italic", title)
  })
}

// Booktabs-style table: rules above, below the header, and at the foot.
#let booktabs(columns: auto, header: (), ..rows) = context if _html() {
  table(columns: columns, table.header(..header), ..rows.pos().flatten())
} else {
  set text(size: 9.5pt)
  set par(leading: 0.5em)
  block(above: 1.4em, below: 1.4em, table(
    columns: columns,
    stroke: none,
    inset: (x: 0pt, y: 0.42em),
    column-gutter: 1.2em,
    align: left + top,
    table.hline(stroke: 0.8pt),
    table.header(..header.map(c => text(style: "italic", c))),
    table.hline(stroke: 0.4pt),
    ..rows.pos().flatten(),
    table.hline(stroke: 0.8pt),
  ))
}

// ---- The handout -----------------------------------------------------------

#let handout(title: "", subtitle: none, date: none, running: none, body) = {
  set document(title: title)
  context if _html() {
    html.elem("style", read("assets/tufte.css") + "\n" + read("assets/handout.css"))
    // tufte-css lays out by <section>, so group the body at each top heading.
    // A plain <blockquote>, without the quotation marks Typst adds.
    show quote.where(block: true): it => html.elem("blockquote", it.body)
    let kids = if body.func() == [].func() { body.children } else { (body,) }
    let sections = ()
    let cur = ()
    for k in kids {
      if k.func() == heading and k.depth == 1 and cur.len() > 0 {
        sections.push(cur)
        cur = ()
      }
      cur.push(k)
    }
    if cur.len() > 0 { sections.push(cur) }
    html.elem("article", {
      html.elem("h1", title)
      if subtitle != none { html.elem("p", attrs: (class: "subtitle"), subtitle) }
      if date != none { html.elem("p", attrs: (class: "date"), date) }
      for s in sections { html.elem("section", s.join()) }
    })
  } else {
    set page(
      paper: "a4",
      margin: (left: _left, right: _right, top: 24mm, bottom: 26mm),
      header: context if here().page() > 1 and running != none {
        // Span the text block and the margin column, so both end flush
        // with the outer edge of the margin notes.
        set text(size: 8pt, tracking: 0.05em)
        block(width: 100% + _gap + _mw, align(right, upper(running)))
      },
      footer: context {
        set text(size: 8.5pt)
        block(width: 100% + _gap + _mw, align(right, counter(page).display()))
      },
    )
    set text(font: _font, size: 11pt, lang: "en", region: "ZA")
    set par(justify: false, leading: 0.68em, spacing: 1.15em)
    set list(indent: 0.4em, body-indent: 0.6em, spacing: 0.75em)
    set enum(indent: 0.4em, body-indent: 0.6em, spacing: 0.75em)
    show quote.where(block: true): it => block(breakable: false, pad(left: 1.6em, top: 0.3em, bottom: 0.3em, it.body))
    show link: it => underline(stroke: 0.35pt, offset: 2pt, it)
    show heading.where(level: 1): it => block(above: 2em, below: 1em, sticky: true,
      text(size: 15pt, style: "italic", weight: "regular", it.body))
    show heading.where(level: 2): it => block(above: 1.6em, below: 0.8em, sticky: true,
      text(size: 12.5pt, style: "italic", weight: "regular", it.body))

    block(below: 0.6em, text(size: 24pt, title))
    if subtitle != none { block(below: 0.5em, text(size: 14pt, style: "italic", subtitle)) }
    if date != none { block(below: 1.6em, text(size: 11pt, style: "italic", date)) }
    body
  }
}
