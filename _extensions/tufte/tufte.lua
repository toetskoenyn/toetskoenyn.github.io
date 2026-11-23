-- tufte.lua: map the Markdown in mapsa.qmd onto the Typst helpers in
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
