
# <%= title %>

## Creating a New Article

To create a new article using this format:

*TODO*: Replace the `<github-organization>` with your GitHub organization.

```bash
quarto use template <github-organization>/<%= filesafename %>
```

This will create a new directory with an example document that uses this format.

## Using with an Existing Document

To add this format to an existing document:

*TODO*: Replace the `<github-organization>` with your GitHub organization.

```bash
quarto add <github-organization>/<%= filesafename %>
```

Then, add the format to your document options:

```yaml
format:
  <%= filesafename %>-pdf: default
```    

## Options

*TODO*: If your format has options that can be set via document metadata, describe them.

## Special Content Blocks

For PDF/LaTeX output, a Lua filter maps fenced Divs and Spans to the
special-content environments and commands provided by Springer Nature's
SNmult/SNmono document classes. For other output formats, these Divs/Spans
are left as-is (rendering as a generic `<div class="...">`/`<span
class="...">`).

### No-argument environments

These classes wrap their content in the matching environment with no
heading:

| Class | LaTeX environment |
|---|---|
| `.svgraybox` | `svgraybox` |
| `.acknowledgement` | `acknowledgement` |

```markdown
::: {.svgraybox}
Emphasized paragraph text, rendered as a screened gray box.
:::
```

### Theorem-like environments

These classes map to SNmult.cls's `\spnewtheorem`-based environments
(`\begin{env}[Name] ... \end{env}`), with an optional `[Name]` argument
supplied via a `name` attribute:

| Class | LaTeX environment |
|---|---|
| `.theorem` | `theorem` |
| `.definition` | `definition` |
| `.claim` | `claim` |
| `.case` | `case` |
| `.conjecture` | `conjecture` |
| `.corollary` | `corollary` |
| `.example` | `example` |
| `.exercise` | `exercise` |
| `.lemma` | `lemma` |
| `.note` | `note` |
| `.problem` | `problem` |
| `.property` | `property` |
| `.proposition` | `proposition` |
| `.question` | `question` |
| `.prob` | `prob` |
| `.sn-proof` | `proof` |
| `.sn-remark` | `remark` |
| `.sn-solution` | `solution` |

```markdown
::: {.theorem name="Pythagoras"}
For a right triangle, $a^2 + b^2 = c^2$.
:::

::: {.lemma}
A lemma with no optional name.
:::
```

`proof`, `remark`, and `solution` are exposed under an `sn-` prefix
(`.sn-proof`, `.sn-remark`, `.sn-solution`) because Quarto itself reserves
the bare class names `proof`/`remark`/`solution` for its own built-in
["Theorems and Proofs"](https://quarto.org/docs/authoring/cross-references.html#theorems-and-proofs)
cross-reference support; using them directly would make Quarto emit its
own conflicting `\newtheorem` definitions alongside SNmult.cls's.

You can register additional `\spnewtheorem` environments you define
yourself under `theorem-environments` in your format metadata:

```yaml
format:
  springer-nature-chapter-pdf:
    theorem-environments: [axiom]
    include-in-header:
      text: |
        \spnewtheorem{axiom}[theorem]{Axiom}{\bfseries}{\itshape}
```

```markdown
::: {.axiom name="Custom Axiom"}
A genuinely custom environment.
:::
```

To alias a custom class name to a differently-named LaTeX environment
(for example, to work around a name collision of your own), supply a
table instead of a plain string:

```yaml
theorem-environments: [{class: sn-lemma2, env: lemma2}]
```

### Titled environments

These classes require a heading, rendered as `\begin{env}{Heading} ...
\end{env}`. The heading comes from (in order of precedence): a `title`
attribute, a leading header inside the div, or a built-in default (matching
the examples in `style_guide/author.tex`):

| Class | LaTeX environment | Default title |
|---|---|---|
| `.trailer` | `trailer` | Trailer Head |
| `.questype` | `questype` | Questions |
| `.important` | `important` | Important |
| `.warning` | `warning` | Attention |
| `.programcode` | `programcode` | Program Code |
| `.tips` | `tips` | Tips |
| `.overview` | `overview` | Overview |
| `.backgroundinformation` | `backgroundinformation` | Background Information |
| `.legaltext` | `legaltext` | Legal Text |

```markdown
::: {.trailer title="Trailer Head"}
Trailer body text.
:::

::: {.important}
## A custom heading
Important body text (heading taken from the leading header).
:::

::: {.warning}
Warning body text (uses the default title "Attention").
:::
```

### Ethics statement

The `.ethics` class maps to the `\ethics{Title}{Text}` command. Supply the
heading via a `title` attribute (it defaults to an empty title if omitted):

```markdown
::: {.ethics title="Competing Interests"}
The authors declare no competing interests.
:::
```

### Run-in headings

`.runinhead`, `.subruninhead`, and `.subsubruninhead` are applied to a
**Span** (not a Div) at the start of a paragraph, mapping to the matching
`\runinhead`/`\subruninhead`/`\subsubruninhead` command:

```markdown
[Run-in Heading]{.runinhead} and the rest of the sentence continues inline.
```

## Known Limitations

- **Quarto reserves certain theorem-like class names.** Quarto's built-in
  ["Theorems and Proofs"](https://quarto.org/docs/authoring/cross-references.html#theorems-and-proofs)
  cross-reference support intercepts Divs with the bare classes `proof`,
  `remark`, or `solution` (regardless of whether the div has a crossref
  `#id`) and injects its own `\newtheorem` definitions, which conflict
  with SNmult.cls's. Use this extension's `.sn-proof`, `.sn-remark`, and
  `.sn-solution` classes instead -- see
  [Theorem-like environments](#theorem-like-environments) above.
- Quarto also reserves `thm-`/`lem-`/`cor-`/`prp-`/`cnj-`/`def-`/`exm-`/`exr-`
  crossref `#id` prefixes (e.g. `{#thm-line}`) for its own numbered-theorem
  cross-referencing, regardless of class. Adding one of these IDs to a
  `.theorem`/`.lemma`/`.corollary`/etc. div will cause Quarto to render its
  own generic theorem environment instead of SNmult.cls's -- omit crossref
  IDs on these divs (SNmult.cls numbers and labels its own environments).

## Example

Here is the source code for a minimal sample document: [template.qmd](template.qmd).

