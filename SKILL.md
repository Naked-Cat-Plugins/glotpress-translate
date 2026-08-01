---
name: glotpress-translate
description: >
  Complete or update GlotPress translations for a project and locale, using the
  nakedcat-glotpress-abilities WordPress plugin's abilities over MCP. Gathers glossary,
  existing-translation, and cross-project consistency context before submitting new
  translations. Triggers: "translate this GlotPress project", "complete missing
  translations for <project> in <locale>", "update GlotPress translations",
  "finish translating <plugin> to <language>".
---

# GlotPress Translate

Orchestrates the `nakedcat-glotpress/*` MCP abilities to translate or complete missing
translations for one GlotPress project in one locale. This skill does not talk to the
WordPress database directly — every GlotPress read/write goes through the abilities. See the
`nakedcat-glotpress-abilities` plugin's own `README.md` for the full schema of each ability; this
skill only summarizes what's needed to call them correctly.

> **Prerequisite:** the abilities must be reachable as MCP tools (see the plugin README's
> "Connecting Claude to these abilities" section for setting up the `mcp-adapter` connection). If
> ability calls aren't available, stop and tell the user to configure that first — don't try to
> work around it by reading the database directly.

## Required inputs

- **project** — a GlotPress project, given as an exact path (`wp-plugins/my-plugin`) or a name to
  resolve.
- **locale** — a target locale, given as an exact GlotPress slug (`pt`, `pt-br`, `pt-ao90`) or a
  name to resolve — "Portuguese" alone is ambiguous, confirm the exact slug rather than guessing.
  Three distinct Portuguese variants exist on this install:
  - `pt` — Portuguese (Portugal), **pre-AO90** spelling. This is the only Portuguese variant this
    skill maintains its own cached official-glossary/rules references for (`references/` — see
    Phase 2's sync step). Never apply those pt-specific caches or rules when translating `pt-br`,
    and never compose `pt-ao90` directly (see below) — this scoping is deliberate, not an
    oversight.
  - `pt-br` — Portuguese (Brazil). A different country's Portuguese, not a pre/post-AO90 variant
    of `pt` — don't conflate the two or treat one as a fallback for the other.
  - `pt-ao90` — Portuguese (Portugal), **post-AO90** spelling. Auto-derived from `pt` when
    `gp-convert-pt-ao90` is active (see Phase 4's guard) — don't translate it directly in the
    normal case.

## Optional flags (ask if not specified, or use these defaults)

| Flag | Default | Effect |
|---|---|---|
| `include_global_glossary` | on | Also consult the locale-wide global glossary, not just the project's own. |
| `check_other_projects` | off | Look up cross-project translation memory for consistency (costs extra ability calls). |
| `use_local_file_references` | off | Grep other plugins'/themes' `.po`/source files on disk for the same locale as extra reference. |
| `use_web_references` | off | Search the web for conventional translations of ambiguous terms. |
| `include_waiting` | off | Also (re-)translate strings already submitted and pending human review. Off by default — don't override someone else's pending work uninvited. |
| `auto_approve` | off | Submit confident translations with `status: "current"` (immediately live) instead of the default `"waiting"`. Off by default — see Phase 4's status policy. |
| `override_current` | off | Allow replacing a string that already has a `current` (approved, live) translation. Off by default — see Phase 4's status policy. |
| `suggest_glossary_additions` | on | At the end of the run, propose new global-glossary terms from the context gathered while translating (see Phase 6). Never writes without confirmation regardless of this flag. |

## Workflow

### Phase 0 — Resolve project and locale

If `project`/`locale` aren't already exact GlotPress values, call
`nakedcat-glotpress/list-projects-translation-status` (optionally with a `locale` filter) to find
the exact `project_path` and confirm a translation set actually exists for the target locale.
GlotPress paths and locale slugs are exact strings every other ability requires — don't guess
them from a human-readable name.

### Phase 1 — Find what needs work

Call `nakedcat-glotpress/get-strings` with `project_path`, `locale`, `status: "untranslated"`.
Paginate with `page`/`per_page` until `page * per_page >= total`.

Then make a **separate** call with `status: "fuzzy"`, and if `include_waiting`, another with
`status: "waiting"`.

**Do not** pass `status: "untranslated_or_fuzzy"` (or any `_or_` combination that omits
`current`) — this is a documented GlotPress query quirk: it silently returns *every* string in
the project, not just the ones actually needing work. One call per status is the reliable way to
combine categories. See the ability's own input schema description for the exact caveat.

Combine the results from these calls into your working list of strings to translate. **Do not**
include a `status: "current"` fetch here by default — already-approved translations are not
targets to retranslate unless the user explicitly asked to review/improve existing translations
(in which case also set `override_current` for Phase 4, and say so back to the user before
proceeding, since it's a one-way replacement of live content).

### Phase 2 — Gather context, before writing anything

1. **Glossary (authoritative — required terms take priority over free translation)**
   - `nakedcat-glotpress/get-glossary` with `project_path` + `locale` (project-scoped; falls back
     to a parent project's glossary automatically if the project has none of its own).
   - If `include_global_glossary`: a second call to the same ability with **only** `locale` (no
     `project_path`) for the locale-wide glossary.
   - Merge both into one term → translation map. On conflict, the project-scoped glossary wins.

2. **Existing translations in this same project (style/tone/register reference)**
   - `nakedcat-glotpress/get-strings` with `status: "current"`.
   - If `total` is large (rough guideline: > 150-200), don't fetch exhaustively just for style
     calibration — pull one or two pages as a representative sample. The point is to match this
     project's existing tone, not to load its entire translated corpus into context.

3. **Cross-project consistency** (only if `check_other_projects`)
   - Take the `singular` strings from Phase 1, chunk into groups of ≤100 (the ability's hard cap),
     and call `nakedcat-glotpress/find-translations-in-other-projects` with `locale` +
     `exclude_project_path` set to the project being translated.
   - Only strings with at least one match come back. Treat these as a strong signal for
     terminology — if two other projects already agree on a translation for the same string,
     don't invent a third wording without a good reason.

4. **Local file references** (only if `use_local_file_references`) — use `Grep`/`Read` directly on
   other plugins'/themes' translation files (`languages/*.po`, bundled `.pot` files) or WordPress
   core's own translations on disk for the same locale. This is filesystem work, not an ability
   call.

5. **Web references** (only if `use_web_references`) — use `WebSearch`/`WebFetch` for how a term
   is conventionally translated elsewhere (e.g. WordPress.org's own glossary/translation for the
   same locale). Prefer official/well-established sources over random pages. For `pt` specifically,
   translate.wordpress.org itself is a strong reference tier beyond our own GlotPress instance —
   search how *other, unrelated* WordPress.org plugins/themes translated the same ambiguous term;
   the Community's own consolidated usage is a better signal than a generic web search.

6. **pt-specific: official glossary + rules cache sync** (only when `locale` is exactly `pt` —
   never `pt-ao90` or `pt-br`, see the locale note above). This skill keeps its own cached
   snapshot of the WordPress Portuguese Community's official pt-PT glossary and translator guide,
   separate from (and in addition to) the GlotPress project/global glossary from step 1.

   - From the skill folder, run `scripts/check-glossary.sh` and `scripts/check-regras.sh`. Each
     prints `MISSING`, `STALE <days>`, or `OK <days>` (30-day threshold).
   - If `MISSING`/`STALE`:
     - Glossary: run `scripts/update-glossary.sh` — downloads the official pt-PT glossary CSV from
       translate.wordpress.org. No confirmation needed; it only refreshes a local cache file, it
       doesn't touch our GlotPress data.
     - Rules: `WebFetch` the live guide
       (`https://pt.wordpress.org/traducoes/guia-de-tradutores-portugues-de-portugal-pt_pt/`),
       rewrite `references/regras-pt.md`'s content to reflect what the page currently says, and
       write today's date to `references/.regras-updated`.
   - If `OK`, skip straight to Phase 3 — don't refresh or re-diff on every run, only when
     stale/missing.
   - **Only when a glossary refresh just happened this run**: diff the freshly-downloaded
     `references/glossario-pt-pt.csv` (`en,pt,pos,description` columns) against the live `pt`
     global glossary already fetched in step 1. A term is a candidate only if it's missing
     entirely — its `en` text doesn't match any existing glossary term under *any* part of
     speech. **Never propose a term that already exists in ours under any part of speech**, even
     if the official translation differs from ours — that's a deliberate divergence to leave
     alone, not something to silently "fix" (see the settings/configurações note below).
   - Present the candidate list (term, pt, pos) and ask the user to confirm before calling
     `add-glossary-entries` — same confirmation requirement as Phase 6, just earlier in the flow
     and sourced differently (this is "add what the official glossary already has and we're
     missing," not evidence gathered from this run's translations).
   - The official CSV sometimes has curly quotes or trailing punctuation/parentheses in term names
     (e.g. `cheating, uh?`, `on/off (adj)`) that `add-glossary-entries` will reject — see the
     term-validation note in Safety/cost notes below before submitting.
   - **Known, deliberate divergence**: our glossary has `settings` → "configurações"; the official
     glossary says "opções". This was a considered decision (2026-07-30), not an oversight —
     never "correct" it during a sync, and don't re-raise it with the user once it's been settled.

### Phase 3 — Translate

For each string from Phase 1:

- Apply glossary terms exactly where they match, before anything else.
- Match the register/tone observed in Phase 2's existing project translations.
- Preserve placeholders (`%s`, `%d`, `%1$s`, etc.) exactly as they appear in `singular`/`plural` —
  don't translate or drop them. A lone unescaped `%` in a string that has placeholders will be
  **rejected outright** by `update-translations`' own validation (this is GlotPress's real
  `sprintf`-safety check, not a style preference — see the plugin README).
- Respect plural forms: the `translations` array from `get-strings` is already trimmed to the
  locale's real plural count (`nplurals`) — only provide that many entries, in the same order.
- **Portuguese orthography**: `pt` (Portuguese, Portugal) is always **pre-AO90** (pre-1990
  Orthographic Agreement) spelling — `activar`, `actualizar`, `desactivar`, `acção`, `óptimo`,
  etc., not the post-1990 forms (`ativar`, `atualizar`, `desativar`, `ação`, `ótimo`). `pt-ao90`
  is the same Portugal Portuguese but **post-AO90** spelling. `pt-br` (Portuguese, Brazil) is a
  separate country's Portuguese entirely — it isn't part of this pre/post-AO90 pairing, don't
  apply `pt`'s pre-AO90 spelling rules to it. In practice the AO90 distinction only matters when
  translating to `pt`: use pre-AO90 spelling consistently. You should essentially never be
  composing `pt-ao90` translations directly anyway (see the `gp-convert-pt-ao90` guard in Phase
  4) — but if a project genuinely has a `pt-ao90` set
  with no corresponding `pt` set, use post-AO90 spelling for it. For `pt` specifically, also load
  and apply `references/regras-pt.md` — a cached distillation of the official Guia de Tradutores
  pt_PT covering register (impersonal infinitive, gender-neutral phrasing, formal address without
  "você"), capitalization (sentence case, not Title Case), acronym pluralization, and adverb
  usage. Refresh it via Phase 2's sync step when stale, not on every run.
- **Punctuation spacing for `pt`** (this skill's own house convention, not from the official
  guide): no space before `: ; ! ?`; render an ellipsis as one character `…`, not three dots
  `...`. Doesn't apply to other locales — use each locale's own typographic convention instead
  (French, for example, *does* use a space before `: ; ! ?` — the opposite rule).
- **Non-text elements stay intact** (every locale, not just `pt`): HTML tags and shortcodes
  (`<strong>`, `<a href="%s">`, `[shortcode]`) — translate the surrounding text, never the
  tag/shortcode syntax itself. Keyboard shortcuts and technical tokens stay as-is (`Ctrl+S`,
  `wp-config.php`). If the source `singular`/`plural` starts or ends with a space, or ends with a
  trailing `:`, preserve that boundary exactly — it's often concatenated with another string at
  render time, and trimming it silently breaks the concatenation.
- **If genuinely unsure about a string (ambiguous context, missing reference), do not translate
  it at all.** Skip it — don't submit anything for it, and don't guess. Report it in Phase 5 as
  deliberately skipped, with why. (If the user explicitly asks for uncertain strings to be
  submitted anyway for human review instead of skipped, use `status: "fuzzy"` for those — but
  that's an opt-in exception, not the default.) **Before concluding a string is ambiguous, read
  the actual source at its `references` file:line** (from `get-strings`) — many ambiguities
  resolve once you see how the string is actually used: is it a button or a heading? Is the
  adjacent value a count, a date, a name? The surrounding code often settles it without needing to
  skip or flag anything.
- Note which source most directly informed each translation as you go (glossary term,
  cross-project match, existing-project style, local file reference, web reference, or composed
  independently with no external reference) — Phase 5 reports a short summary of this.

### Phase 4 — Submit

**Status policy (defaults — override only when the user explicitly asks for different behavior):**

1. **New translations default to `status: "waiting"`, never `"current"`.** Even though this
   plugin's GlotPress-admin permission model would technically auto-approve a `"current"`
   submission, don't use it by default — a translation you produced should land in GlotPress's
   normal human-review queue, not go live immediately. Only submit `status: "current"` directly
   if the user explicitly asked for immediate publish/auto-approval (or set `auto_approve`).
   Low-confidence strings aren't submitted at all by default — they're skipped (see Phase 3);
   `status: "fuzzy"` only comes up if the user explicitly opted into that instead of skipping.
2. **Never replace a string that already has a `current` translation, unless the user explicitly
   asked to (`override_current`).** This is automatically satisfied by rule 1 above in the normal
   case: submitting `status: "waiting"` or `"fuzzy"` never touches or demotes an existing `current`
   row — only a `"current"` submission does that (GlotPress's `set_as_current()` demotes the prior
   current row to `old`). So as long as you're not deliberately targeting already-`current`
   strings from Phase 1 (see that phase's note) and not passing `status: "current"` without
   `auto_approve`/explicit instruction, existing approved translations are safe by construction —
   no extra check is needed. If the user *did* ask to override a current translation, confirm
   which strings before submitting, since the old translation becomes `old` (not deleted, but no
   longer live) and that's a one-way action for that call.

Batch into `nakedcat-glotpress/update-translations` calls of at most 100 items — normally every
item in the batch is `status: "waiting"` (strings you were confident about; anything you weren't
confident about was already left out per Phase 3, not included here as `"fuzzy"`):

```json
{
  "project_path": "...",
  "locale": "...",
  "translations": [
    { "original_id": 123, "translation": ["..."], "status": "waiting" },
    { "original_id": 124, "translation": ["...", "..."], "status": "waiting" }
  ]
}
```

- Every item needs an explicit `status` — there is no default at the ability level; the default
  described above is this skill's own policy, not something the ability enforces for you.
- If the whole call returns a `WP_Error` because `locale` is `pt-ao90` and the project also has a
  `pt` set: that's the plugin's `gp-convert-pt-ao90` guard, not a bug. Translate `pt` instead —
  `pt-ao90` syncs automatically.
- Read every item's `result`: `unchanged` means an identical translation already existed (fine,
  not an error); `error` needs attention — check `error_message` (often a placeholder-safety
  rejection, or an `original_id` that doesn't belong to this project).

### Phase 5 — Report

Tell the user, concretely:
- How many strings were submitted (`created`), broken down by status — how many `waiting`, how
  many `fuzzy`, and (only if `auto_approve` was used) how many `current`.
- How many were already correct (`unchanged`), how many failed (`error`, with why).
- If nothing was set to `current`, say so plainly (e.g. "all N translations are in the `waiting`
  queue for review — nothing was published live") so it's clear no existing or new translation
  went live without being asked for.
- **How many strings were skipped for being genuinely uncertain, and why** (e.g. "3 skipped —
  ambiguous without more context: ..."). This is an expected, routine outcome now (see Phase 3),
  not an edge case — report the count plainly alongside `created`/`unchanged`/`error`, not buried.
- **Always end with a short reference-source breakdown** — where the translations actually came
  from, not just that context was "gathered." One line per source that was actually used, e.g.:
  "19 matched existing translations in other projects (shop-as-client-pro), 4 used glossary
  terms, 1 referenced the local WooCommerce `.po` file, 27 composed independently from context."
  Keep it to a sentence or short list — a source-level summary, not a per-string audit trail
  unless the user asks for one.

If `suggest_glossary_additions` is on, follow this report immediately with Phase 6, in the same
message — don't make the user ask for it separately.

### Phase 6 — Suggest glossary additions (only if `suggest_glossary_additions`)

The point: you already gathered multiple independent sources of terminology evidence while
translating (Phase 2/3) — surface anything strong enough to be worth standardizing globally,
rather than letting that evidence evaporate at the end of the run.

**Candidate bar: a term needs 3+ independent sources agreeing on the same translation before
it's suggested.** Independent sources, each counted separately:
- Each *other* project that independently uses the same translation for the same term (one
  `find-translations-in-other-projects` match = one source; two agreeing projects = two sources).
- This project's own pre-existing (`current`) usage of the same term/translation, if any (one
  source, regardless of how many strings in this project use it).
- The local `.po`/file reference, if `use_local_file_references` was on and it corroborates the
  same translation (one source).
- A distinct web reference, if `use_web_references` was on (one source per distinct authoritative
  source, not per search result).

Repetition within your own newly-composed translations in *this* run does not count as multiple
sources — translating the same term the same way five times in one project is one decision, not
five independent confirmations. Reaching 3 sources realistically requires `check_other_projects`
and/or `use_local_file_references`/`use_web_references` to have been on for this run — if they
were all off, say plainly that there wasn't enough independent evidence gathered this run to
suggest anything, rather than lowering the bar.

**What makes a good candidate term**: a domain-specific, reusable noun/verb/expression (product
UI labels, status names, e-commerce/WordPress vocabulary — the kind of thing already in the
glossary, like "content", "on-hold", "settings") — not a full sentence, not a generic word that
doesn't need standardizing (articles, common verbs with no ambiguity).

**Before suggesting anything**, check it isn't already covered: cross-reference candidates
against the global glossary entries you already fetched in Phase 2.1 — a term already present
(same term + part of speech) is never a candidate, regardless of source count.

**Never write without confirmation.** Present the candidates — term, part of speech, proposed
translation, and which sources support it — and ask the user directly whether to add them. Only
call `nakedcat-glotpress/add-glossary-entries` after they say yes, in a subsequent turn; this
phase itself never calls it unprompted. If there are no candidates meeting the bar, say so briefly
("no glossary suggestions this run — nothing reached 3 independent sources") rather than omitting
the section silently.

Example of the proposal format:

```
Suggested glossary additions (pt):
  - "on-hold" (noun) → "Aguarda confirmação de pagamento"
    sources: WooCommerce .po reference, shop-as-client-pro, another-project-b (3)
  - "order again" (expression) → "Encomendar novamente"
    sources: shop-as-client-pro, another-project-b, another-project-c (3)

Add these 2 to the global pt glossary?
```

When adding, batch them into a single `add-glossary-entries` call (respecting its own 50-item
cap). Report each result the same way Phase 5 reports translations: `created`/`unchanged`/`error`,
and if `error` because the term already exists with a different translation, say so rather than
treating it as a generic failure.

## Safety / cost notes

- Every ability requires the connected user to be a **GlotPress administrator**
  (`GP::$permission->current_user_can('admin')`; WordPress `manage_options` is not required). A
  permission error is not something to route around — surface it to the user.
- Only `nakedcat-glotpress/update-translations` and `nakedcat-glotpress/add-glossary-entries`
  write anything; the other four abilities are read-only — call them as freely as needed for
  context, but don't call either write ability speculatively; only submit a translation or
  glossary entry you've actually composed and (for glossary entries) the user has confirmed.
- Batch caps: `update-translations` and `find-translations-in-other-projects` cap at 100 items
  per call, `add-glossary-entries` at 50 — chunk larger sets.
- `add-glossary-entries` validates `term` strictly: ASCII only, must start and end with a word
  character. Curly quotes, trailing punctuation, or parenthetical qualifiers in a term (e.g.
  `cheating, uh?`, `on/off (adj)`) get rejected — sanitize first (straight apostrophes; move
  anything non-word-boundary into `comment` instead of `term`) rather than dropping the entry.
  Applies to every glossary addition, not just the `pt`-specific sync in Phase 2.
- **Default submission status is `"waiting"`, and existing `current` translations are never
  targeted for replacement — both by default, both requiring explicit opt-in to change** (see
  Phase 4's status policy). Don't drift toward `"current"` submissions "because the translation is
  obviously right" — that judgment call belongs to the user unless they've already delegated it
  via `auto_approve`.
- `references/glossario-pt-pt.csv` and `references/regras-pt.md` (plus their `.{glossary,regras}-updated`
  timestamps) are this skill's own local caches for `pt` only — read/refresh freely per Phase 2's
  sync step, they're not GlotPress data and don't require confirmation to update. The
  `scripts/check-glossary.sh` / `update-glossary.sh` pattern is adapted from
  [fabiomsnunes/wp-translate-pt-pt](https://github.com/fabiomsnunes/wp-translate-pt-pt) (GPLv2).
