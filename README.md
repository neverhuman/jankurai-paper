# jankurai-paper

<!-- jankurai-badge:start -->
[![Jankurai score: 89/100](agent/jankurai-badge.svg)](agent/jankurai-badge.json)
<!-- jankurai-badge:end -->

LaTeX source, paper data, figures, and the build lane for the **jankurai** paper.
This repository is one member of the Jankurai split family; read
[`SPLIT.md`](SPLIT.md) for the family contract and [`AGENTS.md`](AGENTS.md) for
agent routing rules.

## Stack

Rust core + TypeScript/React/Vite product surface + PostgreSQL truth + generated
contracts + exception-only Python AI/data service. This member holds the paper
arm only (TeX manuscript, paper data, and the build lane); see
[`docs/architecture.md`](docs/architecture.md).

## Quick start

```bash
# One-command setup (TeX toolchain components).
just setup

# Deterministic fast lane (build the paper PDF, then self-audit).
just fast

# Full local check: build the paper and run the jankurai self-audit.
just check
```

The full command surface lives in the root [`Justfile`](Justfile). Continuous
integration runs the same lanes under
[`.github/workflows/ci.yml`](.github/workflows/ci.yml) via `ops/ci/*.sh`.

## Layout

| Path | Role |
| --- | --- |
| `paper/` | canonical TeX manuscript, data, figures, and citation ledgers |
| `agent/` | machine-readable owner, test, boundary, and generated-zone maps |
| `docs/` | architecture, testing, boundaries, release, and exception docs |
| `ops/` | pinned CI script entrypoints |
| `scripts/` | local CI helpers |
| `tips/` | short reusable guidance distilled from the paper |
| `assets/` | rendered headers, mascots, and diagrams |

## Documentation

- [Architecture](docs/architecture.md)
- [Testing](docs/testing.md)
- [Boundaries](docs/boundaries.md)
- [Release process](docs/release.md)
- [Agent exceptions and overrides](docs/exceptions.md)

## Versioning

The current version is recorded in [`VERSION`](VERSION) and the change history in
[`CHANGELOG.md`](CHANGELOG.md). Release mechanics are documented in
[`docs/release.md`](docs/release.md).

## License

See [`LICENSE`](LICENSE).
