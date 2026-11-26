# Handout style guide

Status: **approved and implemented** (26 November 2026). D1–D3 were approved explicitly; D4–D9 follow the recommendations.

This guide sets out how every handout looks in print (Typst → PDF) and on screen (Typst → HTML). It is derived from the design template in `_sources/design-template.pdf` and adapted for A4 handouts that keep notes and citations in the margin. Both outputs take their values from one set of tokens (§13), so they can't drift apart.

Section 1 lists the decisions that need your approval. The rest is the specification, with each value marked **M** (measured from the template), **D** (derived from a measurement) or **A** (adapted for the handout, because the template has nothing comparable).

---

## 1. Decisions

| # | Decision | Recommended | Alternative |
|---|----------|-------------|-------------|
| D1 | Page format | **A4, with the template's 116 mm text block and a margin column for notes** (§3) | The template's own trim, 153 × 236 mm, with no margin column; notes become footnotes |
| D2 | Head margin | **57 mm to the first baseline, as in the template** | 35 mm, which fits about 4 more lines on a page |
| D3 | Verdict callouts | **Small-caps label, then the statement at heading size, against a hairline rule** (§10) | Statement at heading size with no rule |
| D4 | Sans-serif display face | **None. Serif only.** | Jost (a free, Futura-like face) for the title only |
| D5 | Newthought openings | **Keep them, as tracked small caps** | Drop them and rely on indents only, as the template does |
| D6 | Tables | **No rules except a hairline under the header row** | No rules at all, as in the template's lists |
| D7 | Figure captions | **Under the image, in the caption column, as in the template** | In the margin column, as now |
| D8 | Page foot | **Folio and running head on every page** | Alternating, as in the book: folio on even pages, running head on odd |
| D9 | Screen size | **HTML body 19 px** (the print proportions scaled up for screen) | 17 px |

---

## 2. What the template is

The template is *Designing Design* by Kenya Hara (Lars Müller Publishers, 2007), designed by Kenya Hara and Kaoru Matsuno. The PDF is 113 scanned pages at 299 ppi, with no usable text layer. The front matter repeats once (pages 9–11 repeat 2–5).

The design rests on a few habits, and the guide keeps all of them:

1. **One typeface, regular weight.** There is no bold anywhere in the running text. Hierarchy comes from size, capitals, letterspacing and space.
2. **A lot of white.** Every text page has a deep head margin. Section openers leave most of the page empty.
3. **A single justified column with deep paragraph indents.** There's no space between paragraphs.
4. **Small type for everything secondary.** Captions, affiliations, lists of works and credits all use one small size.
5. **Spaced capitals for names and titles.** Section titles, running heads and surnames are set in capitals with letterspacing.
6. **Images as objects.** They are cut square, set in rows of equal height, often bleeding to the page edge, with the caption below in a narrower column.
7. **No ornament.** There are no rules, boxes, bullets or colour in the typography. The one exception is a hairline beside a display title (template p. 22).

---

## 3. Page and grid

### Measured (template)

| Element | Value | Source |
|---------|-------|--------|
| Trim | 153.4 × 236.2 mm | M |
| Text block width | 116 mm (116.0–116.3 across pages) | M |
| Outer margin | 25–29 mm (scans are cropped at the gutter, so the inner margin can't be measured) | M |
| First baseline from top | 57 mm | M |
| Last baseline from top | 214 mm | M |
| Lines per full page | 30 | M |
| Leading | 15.0 pt | M |
| Folio/running head baseline | 224 mm (12 mm above the trim) | M |
| Characters per line | about 77 | M |

### Adapted for A4 (D1)

The handout keeps the template's measure and type and adds a margin column on the right for sidenotes and citations.

| Element | Value |
|---------|-------|
| Page | A4, 210 × 297 mm |
| Left margin | 22 mm |
| Text block | 116 mm |
| Gutter | 7 mm |
| Margin column | 50 mm |
| Right margin | 15 mm |
| First baseline (continuation pages) | 57 mm (D2) |
| Last baseline | 268.7 mm (the 41st line on the 15 pt grid) |
| Lines per full page | 41 |
| Foot line baseline | 285 mm |

**Baseline grid.** Body text sits on a 15 pt grid. Headings, captions, lists and figures may break the grid, but the first line of body text after them returns to it. Vertical space comes in multiples of a half line (7.5 pt).

**Image area.** Figures may span the text block (116 mm), or the text block plus gutter plus margin column (173 mm). On the first page of a section they may also bleed to the left edge, as the template does.

---

## 4. Typefaces

| Role | Face | Notes |
|------|------|-------|
| Everything | **EB Garamond** (Georg Duffner and Octavio Pardo, SIL Open Font License) | The closest free match to the template's Garamond. At 11.5 pt it breaks lines in the same places as the template (calibrated on a 116 mm line). It has true small caps, lining and oldstyle figures, and italics. |
| Display sans | none (D4) | The template uses a geometric sans only on its half-title and title pages (book title, author, publisher). A handout has no such pages. |

**Figures.** Lining figures throughout (`lnum`), as in the template's dates and page numbers. Tables use tabular lining figures (`tnum`).

**Small caps.** Use EB Garamond's real small caps (`smcp`, with `c2sc` for text typed in capitals), not scaled-down capitals. This replaces the current fake small caps.

**Font files.** EB Garamond Regular and Italic (TTF, with `OFL.txt`) are bundled in `_extensions/tufte/fonts/`, so the PDF and the HTML use the same files on every machine:
- **Typst:** loads them through `font-paths` in `_extension.yml`, and `--font-path` for the HTML compile.
- **HTML:** `render-html.sh` writes them into `assets/fonts.css` as base64 data URIs. The page is self-contained and makes no font requests.
- **If the font is missing:** Typst warns and substitutes a fallback. Check `pdffonts` (§15).

---

## 5. Type scale

All sizes are for EB Garamond. Sizes were derived by matching x-height (body) or cap height (titles) to the template.

| Token | Role | Size / leading | Case and spacing | Source |
|-------|------|----------------|------------------|--------|
| `display` | Section title (template chapter title) | 33 / 36 pt | Capitals, tracking +0.12 em | D: cap height 21.6 pt |
| `title` | Handout title (template essay title) | 20 / 24 pt | Capitals, tracking +0.08 em | D |
| `subtitle` | Handout subtitle | 20 / 24 pt | Sentence case | D |
| `heading` | Section heading (`#`) | 14 / 15 pt | Sentence case, regular | D: 1.2 × body ink height |
| `subheading` | Sub-heading (`##`) | 11.5 / 15 pt | Italic, sentence case | A |
| `name` | Name line in the opening block | 14 / 15 pt | Given name in lower case, SURNAME in capitals +0.08 em | M (pattern from the template) |
| `body` | Running text | **11.5 / 15 pt** | Justified, hyphenated | D: x-height 4.5 pt, measure 77 characters |
| `small` | Captions, notes, citations, affiliations, tables | 8.25 / 12 pt | Ragged right | D: 0.72 × body |
| `label` | Running head, callout labels, table headers | 8.25 pt small caps | Tracking +0.15 em | D |
| `folio` | Page number | 8.25 pt | Lining figures | D: figure height 5.3 pt |

Use only these sizes. If something seems to need another size, fit it to one of these instead.

**Weight.** Regular and italic only. Bold is never used. Markdown `**strong**` renders as small caps.

---

## 6. Paragraphs

| Property | Value | Source |
|----------|-------|--------|
| Alignment | Justified | M |
| Hyphenation | On, `en-GB` patterns (ZA uses GB) | M |
| First-line indent | 15 mm (about 4 em) | M: 15.4 mm |
| Indent after a heading, figure, list or callout | None | M |
| Space between paragraphs | None | M |
| Widows and orphans | At least 2 lines kept together | A |
| Last line | Never shorter than the indent; rework the text if it is | A |

The deep indent is the template's most recognisable feature. Don't reduce it.

---

## 7. Headings

**Section heading** (`# 1. Summary`): `heading` style.
- **Space:** two blank lines (30 pt) above, then one blank line (15 pt) before the text. M: heading baseline to text baseline is 11 mm.
- **Numbers:** set as written in the Markdown.
- **Hyphenation and alignment:** never hyphenated, never justified.
- **Page breaks:** a heading always starts with at least 2 lines of text below it on the same page.

**Sub-heading** (`## A. ...`): `subheading` style, one blank line above, none below.

**Display title** (`display`): reserved for the first page of a handout set as a section opener (§8). It is not used in running text.

---

## 8. Opening block (first page)

This follows the template's essay openers (template pp. 8, 12, 14, 19).

```
[57 mm white]
SCHOOLING THE NATION                         title: capitals, tracked
Christian National Education in …            subtitle: same size, sentence case
[2 lines]
Christian National Education and …           name line: given name + SURNAME
South Africa, 1948–1994 · Israel today       small, roman
COMPARATIVE STUDY · HISTORY OF EDUCATION     label: small caps, tracked
[3 lines]
1. Summary                                   first heading
```

- **Date:** `small`, set at the foot of the opening block, with the date written as "26 November 2026".
- **Margin note in the opening block:** the website and sources go in the margin column, aligned with the name line.
- **Surname in capitals:** for a person, write the surname in capitals in the Markdown ("Given-name SURNAME"). The style does not change case by itself.

---

## 9. Running head and folio

| Element | Style | Position |
|---------|-------|----------|
| Folio | `folio`: page number, then a thin space, a vertical bar, a thin space and the page count ("3 \| 7") | Foot, left edge of the text block, baseline 285 mm |
| Running head | `label`: text from `running:` in the front matter | Foot, 15 mm (the paragraph indent) after the folio, same baseline |
| First page | No folio or running head | |

The template uses "22 | 23" for each spread. The handout uses the same bar to show page and page count (D8). The HTML has no pages, so it has no folio or running head.

---

## 10. Components

**Verdict callout** (`::: {.verdict label="..."}`, D3), laid out like the display title and its note on template p. 22:
- **Statement:** left, in `heading` style, regular and unhyphenated.
- **Rule:** a 0.4 pt vertical hairline, 4 mm from the statement.
- **Label:** right of the rule, 4 mm from it, in a 32 mm column, in `label` style.
- **Space:** one blank line above and below. No box, no background, no colour.

**Newthought** (`[...]{.newthought}`, D5): small caps at body size, with the lighter small-caps tracking (+0.05 em). The `label` tracking is too wide at body size. Use it at most once per section, as now.

**Sidenote** (numbered) and **margin note** (unnumbered):
- **Type:** `small`.
- **Column and number:** set in the margin column, with the number hanging in a 1.1 em column. The superscript in the text is a lining figure at 70%.
- **Spacing:** 12 pt between notes. The stacking and push-up behaviour is unchanged.

**Citations:** as now. The first citation of a work gives author, year and title in the margin; later ones give "Author Year". The list at the end is in `small`, with entries half a line apart, under a section heading titled "References". Its hanging indent is the one the citation style sets.

**Block quote:**
- **Type:** body size, indented 15 mm on the left only.
- **Space:** one blank line above and below.
- **Attribution:** on its own line in `label` style, set flush right. Template p. 6 is the model: an epigraph in roman with the name in tracked capitals below.

**Language passages** (`lang="af"` and others): no visual change, only the hyphenation language.

**Lists:**
- **Markers:** no bullets. Unordered items use an en dash; ordered items use the number and a full stop. Both hang in a 15 mm column, so the item text lines up with the paragraph indent.
- **Type:** body size and leading. There's no space between items and one blank line around the list.
- **Lead-ins:** italic lead-ins (`*Agriculture.*`) stay italic.

**Tables** (D6):
- **Type:** `small`, with tabular lining figures.
- **Header row:** `label` style, with a 0.4 pt hairline below. No other rules.
- **Columns:** the first column may be italic for years or dates, as in the template's Exhibitions and Awards pages.
- **Space:** columns are separated by 5 mm. Rows are 12 pt lines with a 4 pt gap between rows, so wrapped cells stay readable.

**Figures and image grids** (D7):
- **Width:** a single image spans the text block. A grid uses equal-height images in a row with a 3 mm gutter, matching the rows of squares on template pp. 26, 30 and 34.
- **Caption:** `small`, ragged right, 7.5 pt below the image, indented 20 mm from the left of the text block. M: the caption column starts 20.3 mm inside the text block and ends at its right edge.
- **Space:** one blank line between the caption and the next text.
- **Images:** no borders or shadows, and no rounded corners.

**Links:**
- **PDF:** links look like plain text; the URL is spelled out where it matters.
- **HTML:** links that leave the page get a 1 px underline in the text colour, offset 0.15 em. Citations, which link within the page, read as plain text, as in the PDF. There is no link colour.

---

## 11. Colour

| Token | Value | Use |
|-------|-------|-----|
| `ink` | `#1a1a1a` | All text and rules |
| `paper` | `#ffffff` | Page and screen background |
| `rule` | `#1a1a1a` at 0.4 pt | Hairlines only |

There is no accent colour. Colour only enters through images.

---

## 12. HTML equivalents

Typst writes the HTML too, so the markup is shared. The CSS takes its values from the same tokens.

| Print | Screen |
|-------|--------|
| A4 page, 116 mm text block | Text column `max-width: 28.6em` at body size (equal to 116 mm at 11.5 pt), margin column to the right at the same ratio (50 : 116) |
| Body 11.5 / 15 pt | Body 19 px / 1.304 line-height (the same 15 : 11.5 ratio) (D9) |
| All other sizes | The same ratios to body, set in `em` |
| 57 mm head margin | `padding-top: 6rem` above the title block |
| Justified, hyphenated | `text-align: justify; hyphens: auto; lang="en-GB"` |
| Sidenotes in margin | Floated into the margin column. Below 760 px wide, they collapse behind a toggle, as now |
| Folio and running head | None |
| Hairlines 0.4 pt | `1px` in `ink` at 60% opacity, which looks the same weight on screen |

---

## 13. Tokens: one source for both outputs

All values in this guide live in one file, [`_extensions/tufte/tokens.json`](../_extensions/tufte/tokens.json). Lengths are in mm and type in pt.

- **`tufte.typ`:** reads it with `json("tokens.json")`.
- **Line boxes:** every line box is exactly its leading tall (two thirds above the baseline, one third below). Body text therefore sits on a true 15 pt grid, and space between blocks is added in whole or half lines.
- **HTML export:** `tufte.typ` writes the same values into the page's `<style>` as CSS custom properties. 1rem is the body size, so every length keeps the print proportions.
- **`handout.css`:** uses only those custom properties, never literal sizes.

Changing a value in `tokens.json` changes both outputs.

---

## 14. Where it lives

| File | Holds |
|------|-------|
| `_extensions/tufte/tokens.json` | Every value |
| `_extensions/tufte/tufte.typ` | Page, type and components for PDF and HTML; `**strong**` as small caps |
| `_extensions/tufte/assets/handout.css` | Screen styles, built on the custom properties (replaces `tufte.css`) |
| `_extensions/tufte/fonts/` | EB Garamond Regular and Italic, `OFL.txt` |
| `_extensions/tufte/render-html.sh` | Builds `assets/fonts.css` (generated, git-ignored) and compiles the HTML |
| `_extensions/tufte/tufte.lua` | Wraps everything before the first heading in `#opening[…]`, with its first line as the name line |

## 15. Verification

A handout passes when:

- [ ] Body text measures 11.5 pt on a 15 pt grid, with about 77 characters per line (check a full page with the measuring script used for this guide).
- [ ] Paragraph indent is 15 mm, with no indent after headings.
- [ ] The text block is 116 mm wide; the first baseline is at 57 mm on continuation pages.
- [ ] Only the sizes in §5 appear (check with `pdffonts` and a text-size dump).
- [ ] Only EB Garamond is embedded in the PDF, and the HTML loads only the bundled WOFF2 files (no CDN requests).
- [ ] No bold anywhere.
- [ ] PDF and HTML agree on every ratio in §12: compare a screenshot of the HTML with a PDF page at the same text width.
- [ ] Both handouts render without warnings.
