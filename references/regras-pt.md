# Regras de tradução pt-PT (Portuguese, Portugal)

Cached distillation of the official [Guia de Tradutores pt_PT](https://pt.wordpress.org/traducoes/guia-de-tradutores-portugues-de-portugal-pt_pt/)
— the WordPress Portuguese Community's own translator guide. This file is a
**refreshable cache**, not something to hand-edit: when stale (see
`scripts/check-regras.sh`), re-fetch the live page (`WebFetch`) and rewrite this
file's content, then update `.regras-updated` with today's date.

Applies **only to locale `pt`** (Portuguese, Portugal). Never apply these rules to
`pt-br` (a different country's Portuguese) or compose `pt-ao90` directly
(auto-derived from `pt` — see SKILL.md's locale section).

## Orthography — pre-AO90, always

"Na tradução oficial usa-se o português segundo a norma anterior ao Acordo
Ortográfico de 1990" — pre-AO90 spelling is the official standard for pt-PT
submissions, not the 1990-reform spelling. Conversion to AO90 only works one
direction (pre-AO90 → AO90), so translating in AO90 directly would be
unrecoverable the other way — pre-AO90 is always the source of truth.

Examples: `activar`, `actualizar`, `desactivar`, `acção`, `óptimo`, `directório`,
`selecção`, `contacto`, `excepção` — not `ativar`, `atualizar`, `desativar`,
`ação`, `ótimo`, `diretório`, `seleção`, `contato`, `exceção`.

## Formality and register

- **Infinitivo impessoal** (impersonal infinitive) is the preferred mood for
  actions/descriptions — it describes an action without tying it to a specific
  tense, mood, or person: "Guardar alterações", "Eliminar artigo" — not "Guarde
  alterações", "Elimine artigo".
- **Gender-neutral**: the guide explicitly aims to "eliminar as referências de
  género" — prefer neutral forms over gendered ones like "bem-vindo/a".
- **Formal register, no "você"**: when a string does need to address the user
  directly, use formal 3rd person singular, not the informal "você" common in
  Brazilian Portuguese: "Tem a certeza que pretende…", "Não tem permissão
  para…". (This specific "no você" framing is this skill's own interpretation of
  "formal language" for pt-PT register — not a literal quote from the guide page,
  flagging that distinction.)

## Capitalization

Capitals only on the **first word** when naming a system element — not
English-style Title Case: "Save Draft" → "Guardar rascunho", not "Guardar
Rascunho".

## Acronyms

"Os acrónimos são escritos sem pontos e não têm plural" — no periods, no plural
form: `PDF`, `URL`, `ID` — never `PDFs`, `URLs`, `PDF's`.

## Adverbs in -mente

"Advérbios de modo terminados em 'mente' ... devem ser usados com parcimónia,
de preferência não mais do que um por parágrafo e nunca são acentuados." — use
sparingly (max ~1 per paragraph), never accented: `rapidamente`,
`automaticamente` — not `rápidamente`.

## Style

- **Contextual, not literal**: "As traduções são preferencialmente contextuais
  e não literais" — translate the sense, not word-for-word.
- **Polysemy**: when one English word covers several senses with no single
  Portuguese equivalent, pick the Portuguese word that matches the specific
  context (the glossary documents several of these: `caption`/`captions`/
  `subtitles`, `restore`, `label`, `tag`).
- **Prefer Portuguese over English** wherever a natural Portuguese term exists —
  only keep English for terms explicitly marked as untranslated in the glossary
  (WordPress jargon like `plugin`, `widget`, `hook`, `shortcode`, etc. — see the
  full list in the project/global glossary).

## Quality control (community process — not directly actionable by this skill)

Community-submitted translations on translate.wordpress.org are only approved
if consistent with this guide, the glossary, and the consolidated translation
table; changing an already-consolidated term requires prior community
discussion/consensus. Not directly applicable when writing into our own private
GlotPress instance, but the underlying principle — don't unilaterally overrule
an already-established term — matches this skill's own "never silently
override" defaults (see SKILL.md Phase 4).

---
*Refresh: WebFetch the guide URL above, rewrite this file's content from what
it currently says, and update `.regras-updated` with today's date. Do this when
`scripts/check-regras.sh` reports `STALE`/`MISSING` — not on every translation
run.*
