-- springer-nature-chapter.lua
--
-- Maps Quarto fenced Divs (and a few Spans) to the special-content
-- environments and commands provided by Springer Nature's SNmult/SNmono
-- document classes (see style_guide/SNmult.cls and style_guide/author.tex).
--
-- Only takes effect for latex/pdf output; for other formats the Divs and
-- Spans are left untouched and fall back to Pandoc's default HTML/etc.
-- rendering (a <div class="..."> or <span class="...">).

if not FORMAT:match("latex") then
  return {}
end

-- Environments that take no heading argument: \begin{env} ... \end{env}
local no_arg_envs = {
  svgraybox = "svgraybox",
  acknowledgement = "acknowledgement",
}

-- Theorem-like environments created with SNmult's \spnewtheorem (which
-- wraps LaTeX's standard \newtheorem machinery). These accept an optional
-- `[Name]` argument, e.g. \begin{theorem}[Pythagoras] ... \end{theorem}.
-- Keys are the Div *class* to use in markdown; values are the actual
-- LaTeX *environment* name (usually the same, see note below).
--
-- All of the names below are predefined by SNmult.cls (`proof` is
-- completed by header.tex, since SNmult.cls leaves it commented out).
--
-- `proof`, `remark`, and `solution` are exposed under an `sn-` prefix
-- (`sn-proof`, `sn-remark`, `sn-solution`) because Quarto itself reserves
-- the bare class names `proof`/`remark`/`solution` for its own built-in
-- "Theorems and Proofs" cross-reference support -- using them directly
-- would make Quarto emit its own conflicting `\newtheorem` definitions.
--
-- Any *additional* \spnewtheorem environments you define yourself (e.g.
-- `axiom`) can be used the same way once you list them under
-- `theorem-environments` in your format metadata, e.g.:
--
--   format:
--     springer-nature-chapter-pdf:
--       theorem-environments: [axiom]
--       include-in-header:
--         text: |
--           \spnewtheorem{axiom}[theorem]{Axiom}{\bfseries}{\itshape}
--
-- To alias a custom class name to a differently-named LaTeX environment
-- (for example, to work around a name collision of your own), supply a
-- table instead of a plain string:
--
--       theorem-environments: [{class: sn-lemma2, env: lemma2}]
local default_theorem_envs = {
  theorem = "theorem",
  claim = "claim",
  case = "case",
  conjecture = "conjecture",
  corollary = "corollary",
  definition = "definition",
  example = "example",
  exercise = "exercise",
  lemma = "lemma",
  note = "note",
  problem = "problem",
  property = "property",
  proposition = "proposition",
  question = "question",
  prob = "prob",
  ["sn-proof"] = "proof",
  ["sn-remark"] = "remark",
  ["sn-solution"] = "solution",
}

-- Environments that require a single {Heading} argument:
-- \begin{env}{Heading} ... \end{env}
-- The default heading text matches the examples in style_guide/author.tex
-- and is used when no `title` attribute or leading header is supplied.
local titled_envs = {
  trailer = { env = "trailer", default = "Trailer Head" },
  questype = { env = "questype", default = "Questions" },
  important = { env = "important", default = "Important" },
  warning = { env = "warning", default = "Attention" },
  programcode = { env = "programcode", default = "Program Code" },
  tips = { env = "tips", default = "Tips" },
  overview = { env = "overview", default = "Overview" },
  backgroundinformation = { env = "backgroundinformation", default = "Background Information" },
  legaltext = { env = "legaltext", default = "Legal Text" },
}

-- Run-in heading commands: \runinhead{Heading} continues inline with the
-- rest of the paragraph. Applied via a Span, e.g.
-- [Run-in Heading]{.runinhead} the rest of the sentence...
local runin_commands = {
  runinhead = "runinhead",
  subruninhead = "subruninhead",
  subsubruninhead = "subsubruninhead",
}

local function blocks_to_latex(blocks)
  local result = pandoc.write(pandoc.Pandoc(blocks), "latex")
  return (result:gsub("%s+$", ""))
end

local function inlines_to_latex(inlines)
  return blocks_to_latex({ pandoc.Plain(inlines) })
end

-- Returns the first class in `classes` that is a key in `lookup`, or nil
local function match_class(classes, lookup)
  for _, class in ipairs(classes) do
    if lookup[class] then
      return class
    end
  end
  return nil
end

-- Determines the {Heading} argument for a "titled" environment. Prefers an
-- explicit `title` attribute, then a leading Header block (which is
-- removed from the body), then falls back to `default_title`.
local function extract_title(div, default_title)
  if div.attributes.title then
    return div.attributes.title, div.content
  end

  local content = div.content
  if content[1] and content[1].t == "Header" then
    local title = inlines_to_latex(content[1].content)
    local rest = {}
    for i = 2, #content do
      rest[#rest + 1] = content[i]
    end
    return title, rest
  end

  return default_title, content
end

-- Builds the class -> environment lookup for recognized theorem-like
-- environments: the built-in SNmult.cls environments plus any listed
-- under the document's `theorem-environments` metadata field. Each custom
-- entry may be a plain string (class name == environment name) or a
-- table with explicit `class`/`env` fields to alias the two.
local function build_theorem_envs(meta)
  local envs = {}
  for class, env in pairs(default_theorem_envs) do
    envs[class] = env
  end

  local custom = meta and meta["theorem-environments"]
  if custom then
    for _, v in ipairs(custom) do
      if pandoc.utils.type(v) == "table" and v.class then
        envs[pandoc.utils.stringify(v.class)] = pandoc.utils.stringify(v.env or v.class)
      else
        local name = pandoc.utils.stringify(v)
        envs[name] = name
      end
    end
  end

  return envs
end

local function make_Div(theorem_envs)
  return function(div)
    local class = match_class(div.classes, no_arg_envs)
    if class then
      local env = no_arg_envs[class]
      local body = blocks_to_latex(div.content)
      return pandoc.RawBlock("latex",
        "\\begin{" .. env .. "}\n" .. body .. "\n\\end{" .. env .. "}")
    end

    class = match_class(div.classes, theorem_envs)
    if class then
      local env = theorem_envs[class]
      -- An optional `name` attribute becomes the environment's optional
      -- [Name] argument, e.g. \begin{theorem}[Pythagoras] ... \end{theorem}
      local name = div.attributes.name
      local opt_arg = name and ("[" .. name .. "]") or ""
      local body = blocks_to_latex(div.content)
      return pandoc.RawBlock("latex",
        "\\begin{" .. env .. "}" .. opt_arg .. "\n" .. body .. "\n\\end{" .. env .. "}")
    end

    class = match_class(div.classes, titled_envs)
    if class then
      local spec = titled_envs[class]
      local title, content = extract_title(div, spec.default)
      local body = blocks_to_latex(content)
      return pandoc.RawBlock("latex",
        "\\begin{" .. spec.env .. "}{" .. title .. "}\n" .. body .. "\n\\end{" .. spec.env .. "}")
    end

    if div.classes:includes("ethics") then
      -- \ethics{Title}{Text} is a command, not an environment, and expects
      -- a single block of text as its second argument.
      local title = div.attributes.title or ""
      local body = blocks_to_latex(div.content)
      return pandoc.RawBlock("latex", "\\ethics{" .. title .. "}{" .. body .. "}")
    end

    return nil
  end
end

local function Span(span)
  local class = match_class(span.classes, runin_commands)
  if class then
    local command = runin_commands[class]
    local heading = inlines_to_latex(span.content)
    return pandoc.RawInline("latex", "\\" .. command .. "{" .. heading .. "}")
  end

  return nil
end

local function Pandoc(doc)
  local theorem_envs = build_theorem_envs(doc.meta)
  return doc:walk({ Div = make_Div(theorem_envs), Span = Span })
end

return {
  { Pandoc = Pandoc },
}
