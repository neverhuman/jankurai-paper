# jankurai-paper Architecture

jankurai-paper is the paper arm of the Jankurai split family. It holds the
canonical LaTeX manuscript, the paper data and figures, and the deterministic
build lane that compiles the PDF.

The product standard the wider family defines is:

```text
Rust core + TypeScript/React/Vite product surface + PostgreSQL truth
+ generated contracts + exception-only Python AI/data service
```

This member contains **no product code** — no Rust crate, no web surface, no
PostgreSQL database, and no Python service are committed here. Those stack arms
live in sibling split members. This repo's "source" is the TeX under
`paper/tex/` and its single build lane is `latexmk`.

## Canonical sources

- `paper/jankurai.tex` — thin build wrapper and section order.
- `paper/tex/` — frontmatter, sections, appendices, and generated TeX tables.
- `paper/data/` — the data inputs that back the paper's generated tables.
- `paper/references*.bib` — the bibliography.

The Markdown files under `paper/` (`outline.md`, `jankurai.md`) are planning and
agent-companion companions, not canonical release sources.

## Local workspace ownership

| Path | Role |
| --- | --- |
| `paper/` | canonical TeX manuscript, data, figures, citation ledgers |
| `assets/` | rendered headers, mascots, and diagrams |
| `docs/` | architecture, boundaries, testing, release, exception docs |
| `agent/` | machine-readable owner, test, and generated-zone maps |
| `ops/` | pinned CI script entrypoints |
| `scripts/` | local CI helpers |
| `tips/` | short reusable guidance distilled from the paper |

Agents should prefer [`agent/owner-map.json`](../agent/owner-map.json) and
[`agent/test-map.json`](../agent/test-map.json) for changes, then route to the
smallest proof lane (the `latexmk` paper build, exposed as `just fast`).
