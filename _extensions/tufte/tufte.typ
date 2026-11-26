// tufte.typ: the handout layout, rendered from one source to PDF (A4) and
// HTML. The look follows _design/style-guide.md. Every size, length and
// colour comes from tokens.json, which also feeds the HTML's CSS, so the
// two outputs can't drift apart.
//
//   typst compile main.typ out/mapsa.pdf
//   typst compile --features html --format html main.typ out/mapsa.html

#let T = json("tokens.json")
#let _html() = target() == "html"

// ---- Tokens as Typst values -------------------------------------------------

#let _paper-w = T.page.width * 1mm
#let _paper-h = T.page.height * 1mm
#let _left = T.page.left * 1mm
#let _measure = T.page.measure * 1mm
#let _gap = T.page.gutter * 1mm
#let _mw = T.page.margin_col * 1mm
#let _right = _paper-w - _left - _measure      // gutter + margin column + outer margin

#let _ink = rgb(T.color.ink)
#let _hair = T.space.hairline * 1pt + _ink
#let _indent = T.space.indent * 1mm

// Every line box is exactly its leading tall: two thirds above the baseline,
// one third below, with no extra leading. Lines of the same style therefore
// sit on a fixed grid (15 pt for body text), and space between blocks is
// added in whole or half lines.
#let _edges(lead) = (top-edge: lead * 2 / 3, bottom-edge: -lead / 3)
#let _type(size, lead) = (size: size * 1pt, .._edges(lead * 1pt))

#let _body = _type(T.size.body, T.lead.body)
#let _small = _type(T.size.small, T.lead.small)
#let _heading = _type(T.size.heading, T.lead.body)
#let _title = _type(T.size.title, T.lead.title)
#let _line = T.lead.body * 1pt                 // one blank line

// Page box: the first baseline sits at first_baseline, and the text area
// holds exactly `lines` lines.
#let _top = T.page.first_baseline * 1mm - _line * 2 / 3
#let _area = _line * T.page.lines
#let _bottom = _paper-h - _top - _area

// ---- Small typographic helpers ---------------------------------------------

// Real small caps from the font (smcp + c2sc), lightly tracked.
#let sc(body) = context if _html() {
  html.elem("span", attrs: (class: "smallcaps"), body)
} else {
  text(tracking: T.track.smallcaps * 1em, hyphenate: false, smallcaps(all: true, body))
}

// Labels: running head, callout labels, table headers.
#let _label(body) = text(tracking: T.track.label * 1em, hyphenate: false, smallcaps(all: true, body))

// Run-in opening for a paragraph, in small caps. At body size it takes the
// lighter small-caps tracking; the label tracking is for small type.
#let newthought(body) = context if _html() {
  html.elem("span", attrs: (class: "newthought"), body)
} else {
  text(tracking: T.track.smallcaps * 1em, hyphenate: false, smallcaps(all: true, body))
}

// Name line of the opening block: heading size.
#let name(body) = context if _html() {
  html.elem("span", attrs: (class: "name"), body)
} else {
  text(.._heading, body)
}

// ---- Margin column (PDF) ---------------------------------------------------

#let _margin-block(body) = block(width: _mw, {
  set text(.._small)
  set par(justify: false, leading: 0pt, spacing: T.lead.small * 0.5pt, first-line-indent: 0pt)
  body
})

// Margin items stack so they never overlap. Each item records its id, the
// height it wants (level with its anchor) and its own height, then lays out
// every item on its page:
//   1. top to bottom, an item that would collide is pushed below the one above;
//   2. bottom to top, items that would run past the foot of the text block
//      are pulled up into free space above.
// The recorded values don't depend on one another, so the layout settles in
// a couple of passes however many items share a page.
#let _mc = counter("tufte-margin-item")

#let _place-margin(body) = {
  _mc.step()
  context {
    let pos = here().position()
    let id = _mc.get().first()
    let content = _margin-block(body)
    let h = measure(content).height
    // here() sits on the anchor's baseline; lift the item by its first
    // line's top edge so the two baselines align.
    let want = pos.y - T.lead.small * 2pt / 3
    let me = (id: id, want: want, h: h)
    [#metadata(me)<tufte-margin>]

    let items = query(<tufte-margin>)
      .filter(m => m.location().page() == pos.page and m.value.id != id)
      .map(m => m.value)
    items.push(me)
    items = items.sorted(key: it => it.id)

    let gap = T.space.note_gap * 1pt
    let ys = ()
    let bottom = none
    for it in items {
      let y = if bottom == none { it.want } else { calc.max(it.want, bottom) }
      ys.push(y)
      bottom = y + it.h + gap
    }
    let limit = _paper-h - _bottom
    for i in range(items.len() - 1, -1, step: -1) {
      let y = calc.max(calc.min(ys.at(i), limit - items.at(i).h), _top)
      ys.at(i) = y
      limit = y - gap
    }
    let y = ys.at(items.position(it => it.id == id))

    box(width: 0pt, height: 0pt, place(
      top + left,
      dx: _left + _measure + _gap - pos.x,
      dy: y - pos.y,
      content,
    ))
  }
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
      // The mark and the note's anchor share one unbreakable box, so a line
      // break can't fall between them and misplace the note.
      // The number hangs in its own column, so every line of a note,
      // including each entry of a multi-source citation, sits beside it.
      // The word joiner keeps the mark on the same line as the word before.
      sym.wj
      box({
        super(n)
        _place-margin(grid(columns: (1.1em, 1fr), super(n), body))
      })
    }
  }
}

// First citation of a work in the margin: author, year and title only
// (margin-entry.csl). The list at the end has the rest.
#let margin-entry(key) = cite(key, form: "full", style: "margin-entry.csl")

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
      box(_place-margin(body))
    }
  }
}

// Bibliography that citations can use but that doesn't print
// (`reference-list: false`). HTML needs the list in the page to link to,
// so there it is hidden rather than left out.
#let hidden-bibliography(..sources) = context {
  let b = bibliography(..sources.pos(), title: none)
  if _html() { html.elem("div", attrs: (hidden: "hidden"), b) } else { place(hide(b)) }
}

// ---- Opening block ---------------------------------------------------------

// The handout's date, set by handout() and printed at the foot of the
// opening block.
#let _date = state("handout-date", none)

// Everything before the first heading: name line, place, roles, with the
// sources in the margin. tufte.lua wraps it in #opening[...].
#let opening(body) = context {
  let date = _date.get()
  if _html() {
    html.elem("div", attrs: (class: "opening"), {
      body
      if date != none { html.elem("p", attrs: (class: "date"), date) }
    })
  } else {
    block(above: 2 * _line, below: 0pt, {
      set text(.._small)
      set par(justify: false, first-line-indent: 0pt, spacing: _line)
      body
      if date != none { par(date) }
    })
  }
}

// ---- Figures and blocks ----------------------------------------------------

// Grid of images, cropped to a common 3:2 frame so each row has one height,
// with the caption below in the caption column.
#let gridfigure(caption: none, columns: 2, ..images) = context if _html() {
  html.elem("figure", attrs: (class: "image-grid"), {
    html.elem("div", attrs: (class: "grid"), images.pos().join())
    html.elem("figcaption", caption)
  })
} else {
  let cells = images.pos().map(img => layout(size => box(
    width: 100%,
    height: size.width / columns * 2 / 3,
    clip: true,
    { set image(width: 100%, height: 100%, fit: "cover"); img },
  )))
  block(width: 100%, above: _line, below: _line, breakable: false, {
    grid(columns: (1fr,) * columns, gutter: T.space.image_gutter * 1mm, ..cells)
    v(_line / 2, weak: false)
    pad(left: T.space.caption_indent * 1mm, {
      set text(.._small)
      set par(justify: false, first-line-indent: 0pt)
      caption
    })
  })
}

// Verdict: the statement at heading size, a hairline, then the label in
// small caps, after the display title and its note on template p. 22.
#let callout(label: none, title) = context if _html() {
  html.elem("div", attrs: (class: "callout"), {
    html.elem("p", attrs: (class: "callout-statement"), title)
    html.elem("p", attrs: (class: "callout-label"), label)
  })
} else {
  let g = T.space.rule_gap * 1mm
  block(above: _line, below: _line, breakable: false, grid(
    columns: (1fr, T.space.callout_label * 1mm),
    stroke: (x, y) => if x == 1 { (left: _hair) },
    inset: (x, y) => if x == 0 { (right: g) } else { (left: g) },
    {
      set text(.._heading, hyphenate: false)
      set par(justify: false, first-line-indent: 0pt)
      title
    },
    {
      set text(.._small)
      set par(justify: false, first-line-indent: 0pt)
      _label(label)
    },
  ))
}

// Table: small type, tabular figures, a hairline under the header only.
#let booktabs(columns: auto, header: (), ..rows) = context if _html() {
  table(columns: columns, table.header(..header), ..rows.pos().flatten())
} else {
  block(above: _line, below: _line, {
    set text(.._small, number-width: "tabular")
    set par(justify: false, first-line-indent: 0pt, leading: 0pt)
    let pad = T.space.row_gap * 1pt
    table(
      columns: columns,
      stroke: none,
      column-gutter: T.space.table_gutter * 1mm,
      inset: (x, y) => (x: 0pt, top: if y == 0 { 0pt } else { pad / 2 }, bottom: pad / 2),
      align: left + top,
      table.header(..header.map(c => _label(c))),
      table.hline(stroke: _hair),
      ..rows.pos().flatten(),
    )
  })
}

// ---- Running head and folio (PDF) -----------------------------------------

// The foot line, placed absolutely so its baseline lands on foot_baseline:
// "3 | 7", then the running head after one paragraph indent.
#let _foot(running) = context {
  let n = here().page()
  if n == 1 { return }
  let total = counter(page).final().first()
  place(top + left, dx: _left, dy: T.page.foot_baseline * 1mm - T.lead.small * 2pt / 3, {
    set text(.._small, number-type: "lining")
    box(width: _indent, [#n#h(0.25em)|#h(0.25em)#total])
    if running != none { _label(running) }
  })
}

// ---- The handout -----------------------------------------------------------

// CSS custom properties for the HTML, computed from the same tokens.
// 1rem is the body size, so every length is in rem and keeps the print
// proportions.
#let _css-vars() = {
  let r(x) = str(calc.round(x, digits: 4))
  let b = T.size.body
  let rem(mm) = r(mm * 72 / 25.4 / b) + "rem"
  let v = (
    "ink": T.color.ink,
    "paper": T.color.paper,
    "body-px": str(T.screen.body_px) + "px",
    "lead": r(T.lead.body / b),
    "small": r(T.size.small / b) + "rem",
    "small-lead": r(T.lead.small / T.size.small),
    "heading": r(T.size.heading / b) + "rem",
    "heading-lead": r(T.lead.body / T.size.heading),
    "title": r(T.size.title / b) + "rem",
    "title-lead": r(T.lead.title / T.size.title),
    "line": r(T.lead.body / b) + "rem",
    "measure": rem(T.page.measure),
    "gutter": rem(T.page.gutter),
    "margin-col": rem(T.page.margin_col),
    "indent": rem(T.space.indent),
    "caption-indent": rem(T.space.caption_indent),
    "image-gutter": rem(T.space.image_gutter),
    "table-gutter": rem(T.space.table_gutter),
    "row-gap": r(T.space.row_gap / b) + "rem",
    "rule-gap": rem(T.space.rule_gap),
    "callout-label": rem(T.space.callout_label),
    "note-gap": r(T.space.note_gap / b) + "rem",
    "track-title": r(T.track.title) + "em",
    "track-label": r(T.track.label) + "em",
    "track-smallcaps": r(T.track.smallcaps) + "em",
    "head": str(T.screen.head_em) + "rem",
  )
  ":root {\n" + v.pairs().map(((k, x)) => "  --" + k + ": " + x + ";").join("\n") + "\n}\n"
}

#let handout(title: "", subtitle: none, date: none, running: none, body) = {
  set document(title: title)
  _date.update(date)
  show strong: it => sc(it.body)
  set bibliography(title: [References])

  context if _html() {
    html.elem("style", _css-vars() + read("assets/fonts.css") + "\n" + read("assets/handout.css"))
    // A plain <blockquote>, without the quotation marks Typst adds.
    show quote.where(block: true): it => html.elem("blockquote", it.body)
    // Group the body into a <section> at each top-level heading.
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
      html.elem("header", {
        html.elem("h1", title)
        if subtitle != none { html.elem("p", attrs: (class: "subtitle"), subtitle) }
      })
      for s in sections { html.elem("section", s.join()) }
    })
  } else {
    set page(
      width: _paper-w,
      height: _paper-h,
      margin: (left: _left, right: _right, top: _top, bottom: _bottom),
      header: none,
      footer: none,
      background: _foot(running),
    )
    set text(
      font: T.font.family,
      .._body,
      fill: _ink,
      lang: "en",
      region: "ZA",
      hyphenate: true,
      number-type: "lining",
    )
    set par(justify: true, leading: 0pt, spacing: 0pt, first-line-indent: _indent)
    set block(spacing: _line)
    // Typst right-aligns list markers; align the dash left so it hangs at the
    // start of its indent-wide column, like the numbers of an enum.
    set list(marker: box(width: _indent, align(left)[–]), indent: 0pt, body-indent: 0pt, spacing: 0pt)
    set enum(
      numbering: n => box(width: _indent)[#n.],
      number-align: start + top,
      indent: 0pt,
      body-indent: 0pt,
      spacing: 0pt,
    )
    show quote.where(block: true): it => block(above: _line, below: _line, pad(left: _indent, it.body))
    show heading: set par(justify: false, first-line-indent: 0pt)
    show heading: set text(hyphenate: false, weight: "regular")
    show heading.where(level: 1): it => block(above: 2 * _line, below: _line, sticky: true,
      text(.._heading, it.body))
    show heading.where(level: 2): it => block(above: _line, below: 0pt, sticky: true,
      text(style: "italic", it.body))
    show heading.where(level: 3): it => block(above: _line, below: 0pt, sticky: true,
      text(style: "italic", it.body))
    show figure.caption: it => pad(left: T.space.caption_indent * 1mm, {
      set text(.._small)
      set par(justify: false, first-line-indent: 0pt)
      align(left, it.body)
    })
    set figure(gap: _line / 2)
    show figure: set block(above: _line, below: _line)
    show bibliography: it => {
      set text(.._small)
      set par(justify: false, first-line-indent: 0pt)
      set block(spacing: T.lead.small * 0.5pt)
      show heading: set block(above: 2 * _line, below: _line)
      it
    }

    // Title block: title in tracked capitals, subtitle in sentence case,
    // both at title size, then two blank lines.
    block(below: 2 * _line, {
      set text(.._title, hyphenate: false)
      set par(justify: false, first-line-indent: 0pt)
      text(tracking: T.track.title * 1em, upper(title))
      if subtitle != none { linebreak(); subtitle }
    })
    body
  }
}
