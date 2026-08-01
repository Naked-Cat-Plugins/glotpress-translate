# GlotPress Translate — Claude Code skill

A [Claude Code](https://docs.claude.com/claude-code) skill that completes or updates WordPress
GlotPress translations for a project and locale, using the
[`nakedcat-glotpress-abilities`](https://github.com/Naked-Cat-Plugins/glotpress-abilities)
WordPress plugin's abilities over MCP.

## What it does

- Orchestrates the `nakedcat-glotpress/*` MCP abilities to translate, or complete missing
  translations for, one GlotPress project in one locale.
- Gathers glossary, existing-translation, and (optionally) cross-project consistency context
  before submitting new translations.
- For `pt` (Portuguese, Portugal) specifically, maintains a refreshable cache of the official
  pt-PT glossary and the WordPress Portuguese Community's own translator guide (*Guia de
  Tradutores*), so runs stay aligned with the community's standard without re-fetching either on
  every call — see `scripts/check-glossary.sh`, `scripts/check-regras.sh`, and
  `scripts/update-glossary.sh`.

Full behavior — required inputs, optional flags, the translation workflow phases, and the
pt/pt-br/pt-ao90 locale handling — is documented in [`SKILL.md`](SKILL.md).

## Requirements

- The [`nakedcat-glotpress-abilities`](https://github.com/Naked-Cat-Plugins/glotpress-abilities)
  plugin, installed and active on the target GlotPress site.
- An Abilities-API-to-MCP bridge connecting those abilities to Claude Code as MCP tools — the
  [`mcp-adapter`](https://github.com/WordPress/mcp-adapter) plugin is the one this skill assumes.
  See glotpress-abilities' own README, ["Connecting Claude to these
  abilities"](https://github.com/Naked-Cat-Plugins/glotpress-abilities#connecting-claude-to-these-abilities),
  for the connection walkthrough.

## Installation

Copy this folder into `~/.claude/skills/glotpress-translate/` for a user-level skill available in
every project, or into a project's own `.claude/skills/` to scope it to that project.

## Locales

- `pt` — Portuguese (Portugal), pre-AO90 spelling. The only variant with dedicated cached
  glossary/rules references in `references/`.
- `pt-br` — Portuguese (Brazil). A different country's Portuguese, never conflated with `pt`.
- `pt-ao90` — Portuguese (Portugal), post-AO90 spelling. Auto-derived from `pt`, not composed
  directly.

## Resources

Official pt-PT sources this skill caches and consults (see `SKILL.md` Phase 2.6 for the sync
mechanics):

- [Official pt-PT glossary](https://translate.wordpress.org/locale/pt/default/glossary/) —
  translate.wordpress.org's consolidated Portuguese (Portugal) glossary; source of
  `references/glossario-pt-pt.csv`, refreshed via `scripts/update-glossary.sh`.
- [Guia de Tradutores pt_PT](https://pt.wordpress.org/traducoes/guia-de-tradutores-portugues-de-portugal-pt_pt/) —
  the WordPress Portuguese Community's own translator guide (orthography, register, capitalization,
  adverb usage); source of `references/regras-pt.md`.
- [translate.wordpress.org — pt locale](https://translate.wordpress.org/locale/pt/) — the broader
  reference tier this skill searches for how other, unrelated projects translated an ambiguous
  term, when `use_web_references` is on.

Related projects:

- [Naked-Cat-Plugins/glotpress-abilities](https://github.com/Naked-Cat-Plugins/glotpress-abilities) —
  the companion WordPress plugin this skill orchestrates over MCP.
- [WordPress/mcp-adapter](https://github.com/WordPress/mcp-adapter) — bridges the WordPress
  Abilities API (what glotpress-abilities registers its abilities through) to MCP clients like
  Claude Code.
- [Introducing the Abilities API](https://make.wordpress.org/core/2025/09/17/introducing-the-abilities-api/) —
  the WordPress core announcement for the API this whole chain is built on.
- [GlotPress](https://wordpress.org/plugins/glotpress/) — the WordPress translation management
  plugin this skill ultimately reads from and writes to.

## Attribution

The cache/staleness-check/refresh pattern in `scripts/check-glossary.sh` and
`scripts/update-glossary.sh` is adapted from
[fabiomsnunes/wp-translate-pt-pt](https://github.com/fabiomsnunes/wp-translate-pt-pt) (GPL-2.0) —
same check/refresh mechanism, retargeted at this skill's own `references/` folder and workflow.

## License

GPL-2.0-or-later — see [`LICENSE`](LICENSE).
