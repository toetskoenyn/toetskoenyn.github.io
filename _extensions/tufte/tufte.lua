-- tufte.lua: map the Markdown in each handout (.qmd) onto the Typst helpers in
-- tufte.typ, so the text stays plain Markdown and Typst controls the look.
--
--   [^note]                      -> #sidenote[...]
--   [text]{.marginnote}          -> #marginnote[...]
--   [text]{.newthought}          -> #newthought[...]
--   [text]{.smallcaps}           -> #sc[...]
--   ::: {.verdict label="..."}   -> #callout(label: [...])[...]
--   ::: {.image-grid}            -> #gridfigure(caption: [...], image(...), ...)
--   ::: {lang="af"}              -> #[#set text(lang: "af") ...]
--   pipe tables                  -> #booktabs(...)
--   [@key; @key2]                -> #sidenote[...] with the citations
--   @key (in a sentence)         -> Author (Year), plus a sidenote the first time
--   blocks before the first #    -> #opening[...], its first line as #name[...]
--
-- Citations follow the Tufte books: the source sits in the margin beside
-- the claim. The first citation of a work gives author, year and title
-- (margin-entry in tufte.typ), later ones "Author Year". A citation inside
-- a footnote joins that sidenote. The handout's `bibliography:` file supplies the entries; `reference-list:
-- false` keeps the list at the end from printing.

if not FORMAT:match("typst") then
  return {}
end

local writer_opts = pandoc.WriterOptions({ wrap_text = "wrap-none" })

-- Inlines -> Typst markup, safe to place inside a [...] content block.
local function markup(inlines)
  local s = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "typst", writer_opts)
  s = s:gsub("%s+$", "")
  -- Inside [...] the text sits at the start of a line, where "1. ", "- ",
  -- "+ " and "= " would open a list or heading.
  s = s:gsub("^(%d+)%. ", "%1\\. "):gsub("^([%-%+=]) ", "\\%1 ")
  return s
end

local function blocks_markup(blocks)
  return markup(pandoc.utils.blocks_to_inlines(blocks))
end

local function raw(s)
  return pandoc.RawInline("typst", s)
end

local function rawb(s)
  return pandoc.RawBlock("typst", s)
end

local function str_literal(s)
  return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

-- Pandoc writes ’ as ', and Typst's smart quotes turn a word-initial '
-- into an opening quote, so Afrikaans ’n would come out as ‘n. Pass a
-- word-initial apostrophe through literally.
function Str(el)
  local rest = el.text:match("^’(.+)")
  if rest then
    return { raw("’"), pandoc.Str(rest) }
  end
end

-- Keep curly quotes literal too, so they survive where Typst applies no
-- smart quotes (the document title in the HTML <title>, for one).
function Quoted(el)
  local open, close = "‘", "’"
  if el.quotetype == "DoubleQuote" then open, close = "“", "”" end
  local out = pandoc.Inlines({ raw(open) })
  out:extend(el.content)
  out:insert(raw(close))
  return out
end

-- ---- Citations --------------------------------------------------------------

local cited = {}

-- One citation as Typst code ending in ";", which closes the embedded
-- expression so the text after it can't be read as part of it.
local function cite_call(id, form)
  if form == "full" then
    return "#margin-entry(label(" .. str_literal(id) .. "));"
  end
  return "#cite(label(" .. str_literal(id) .. "), form: " .. str_literal(form) .. ");"
end

local function cite_item(c)
  local first = not cited[c.id]
  cited[c.id] = true
  local s
  if c.mode == "AuthorInText" then
    s = cite_call(c.id, "prose")
  elseif first then
    s = cite_call(c.id, "full")
  elseif c.mode == "SuppressAuthor" then
    s = cite_call(c.id, "year")
  else
    -- "~", not a space: Typst merges cites separated only by spaces into
    -- one group and would print "Author; Year".
    s = cite_call(c.id, "author") .. "~" .. cite_call(c.id, "year")
  end
  if #c.prefix > 0 then s = markup(c.prefix) .. " " .. s end
  if #c.suffix > 0 then s = s .. markup(c.suffix) end
  return { s = s, full = first and c.mode ~= "AuthorInText" }
end

-- Short citations run on with "; "; each full entry gets its own line.
-- `terminal` ends the group with a full stop, for a sidenote that holds
-- only citations.
local function cite_group(cite, terminal)
  local items = {}
  for _, c in ipairs(cite.citations) do table.insert(items, cite_item(c)) end
  local out = {}
  for i, it in ipairs(items) do
    if i > 1 then
      local prev = items[i - 1]
      table.insert(out, prev.full and ".#linebreak()" or (it.full and ";#linebreak()" or "; "))
    end
    table.insert(out, it.s)
  end
  if terminal then table.insert(out, ".") end
  return table.concat(out)
end

-- A citation in running text: Author (Year) stays in the sentence, with the
-- full entry in the margin the first time; any other kind moves into the
-- margin as a sidenote.
local function cite_in_text(cite)
  local c = cite.citations[1]
  if #cite.citations == 1 and c.mode == "AuthorInText" then
    local first = not cited[c.id]
    local out = { raw(cite_group(cite, false)) }
    if first then
      table.insert(out, raw("#sidenote[" .. cite_call(c.id, "full") .. ".]"))
    end
    return out
  end
  return { raw("#sidenote[" .. cite_group(cite, true) .. "]") }
end

local function in_margin(cite)
  return cite.citations[1].mode ~= "AuthorInText"
end

-- Runs first, in document order, so "first citation" means first on the page.
local citations = {
  traverse = "topdown",
  -- "claim [@key]" -> "claim¹": drop the space before a margin citation.
  Inlines = function(ils)
    for i = #ils, 2, -1 do
      if ils[i].t == "Cite" and in_margin(ils[i])
        and (ils[i - 1].t == "Space" or ils[i - 1].t == "SoftBreak") then
        ils:remove(i - 1)
      end
    end
    return ils
  end,
  Note = function(el)
    return el:walk({ Cite = function(c) return raw(cite_group(c, false)) end }), false
  end,
  Cite = function(el)
    return cite_in_text(el), false
  end,
}

function Note(el)
  return raw("#sidenote[" .. blocks_markup(el.content) .. "]")
end

local span_fns = { marginnote = "marginnote", newthought = "newthought", smallcaps = "sc" }

function Span(el)
  for class, fn in pairs(span_fns) do
    if el.classes:includes(class) then
      return raw("#" .. fn .. "[" .. markup(el.content) .. "]")
    end
  end
end

function SmallCaps(el)
  return raw("#sc[" .. markup(el.content) .. "]")
end

local function image_grid(div)
  local images, caption = {}, {}
  for _, block in ipairs(div.content) do
    local found = false
    block:walk({
      Image = function(img)
        found = true
        local alt = pandoc.utils.stringify(img.caption)
        table.insert(images, "image(" .. str_literal(img.src) .. ", alt: " .. str_literal(alt) .. ")")
      end,
    })
    if not found then
      caption = block.content or caption
    end
  end
  return rawb("#gridfigure(\n  caption: [" .. markup(caption) .. "],\n  "
    .. table.concat(images, ",\n  ") .. ",\n)")
end

function Div(el)
  if el.classes:includes("verdict") then
    local label = pandoc.Inlines(el.attributes.label or "")
    return rawb("#callout(label: [" .. markup(label) .. "])[" .. blocks_markup(el.content) .. "]")
  end
  if el.classes:includes("image-grid") then
    return image_grid(el)
  end
  local lang = el.attributes.lang
  if lang then
    local out = { rawb("#[#set text(lang: " .. str_literal(lang) .. ")") }
    for _, b in ipairs(el.content) do table.insert(out, b) end
    table.insert(out, rawb("]"))
    return out
  end
end

function Table(tbl)
  local function row(r)
    local cells = {}
    for _, c in ipairs(r.cells) do
      table.insert(cells, "[" .. blocks_markup(c.contents) .. "]")
    end
    return "(" .. table.concat(cells, ", ") .. ",)"
  end

  local widths = {}
  for _, spec in ipairs(tbl.colspecs) do
    local w = spec[2]
    table.insert(widths, type(w) == "number" and string.format("%dfr", math.floor(w * 100 + 0.5)) or "auto")
  end

  local lines = { "#booktabs(", "  columns: (" .. table.concat(widths, ", ") .. ",)," }
  local head = tbl.head.rows[1]
  if head then table.insert(lines, "  header: " .. row(head) .. ",") end
  for _, body in ipairs(tbl.bodies) do
    for _, r in ipairs(body.body) do
      table.insert(lines, "  " .. row(r) .. ",")
    end
  end
  table.insert(lines, ")")
  return rawb(table.concat(lines, "\n"))
end

-- The opening block: everything before the first top-level heading. Its
-- first line (up to the first line break) is the name line. Runs last, when
-- the spans in it are already Typst markup.
local function Pandoc(doc)
  local first = nil
  for i, b in ipairs(doc.blocks) do
    if b.t == "Header" and b.level == 1 then first = i; break end
  end
  if not first or first == 1 then return nil end
  local head = {}
  for i = 1, first - 1 do table.insert(head, doc.blocks[i]) end
  local p = head[1]
  if p.t == "Para" or p.t == "Plain" then
    local ils = p.content
    local lead, name_ils, rest, seen = pandoc.Inlines({}), pandoc.Inlines({}), pandoc.Inlines({}), false
    for _, il in ipairs(ils) do
      if seen then
        rest:insert(il)
      elseif il.t == "LineBreak" then
        seen = true
        rest:insert(il)
      elseif #name_ils == 0 and il.t == "RawInline" then
        lead:insert(il)            -- a margin note before the name stays outside it
      else
        name_ils:insert(il)
      end
    end
    if seen and #name_ils > 0 then
      local out = pandoc.Inlines(lead)
      out:insert(raw("#name["))
      out:extend(name_ils)
      out:insert(raw("]"))
      out:extend(rest)
      head[1] = pandoc.Para(out)
    end
  end
  local blocks = { rawb("#opening[") }
  for _, b in ipairs(head) do table.insert(blocks, b) end
  table.insert(blocks, rawb("]"))
  for i = first, #doc.blocks do table.insert(blocks, doc.blocks[i]) end
  doc.blocks = blocks
  return doc
end

-- Citations first, so the notes they create go through Note below.
return {
  citations,
  {
    Str = Str, Quoted = Quoted, Note = Note, Span = Span,
    SmallCaps = SmallCaps, Div = Div, Table = Table,
  },
  { Pandoc = Pandoc },
}
