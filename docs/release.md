# Release process

GitHub is authoritative for `neverhuman/jankurai-paper`; `.jeryu/` records
historical integration metadata. Release tags use
`jankurai-paper-v<MAJOR.MINOR.PATCH>-split.<N>` from [SPLIT.md](../SPLIT.md).

## Version and changelog

[`VERSION`](../VERSION), `agent/standard-version.toml`, and the proposed tag
must agree. Record actual changes in [CHANGELOG.md](../CHANGELOG.md), then
promote `Unreleased` to a dated version section in the reviewed release commit.
The private Node package contains CI tooling and is not separately published.

## Qualification before tagging

1. Install selected tools and TeX packages from `ops/ci/github-setup.sh` and the
   pinned workflow, use Node 24, and run `npm ci`.
2. Run `bash scripts/ci-doctor.sh`, then `just check`. The full gate includes
   tooling tests, TeX build, baseline comparison, strict security, actual proof
   execution and verification, required proofbind, and zero-drop ratchet.
   Resolve every failure.
3. Review the complete PR diff and actual successful `quality` and
   `jankurai-paper/required` checks for its exact head. Merge through protection
   and qualify resulting main and its immutable `ci-<full-sha>` tag.
4. Retain the PDF, its SHA-256, audit and proof reports, security evidence,
   source commit/tree, and actual tool identities. Verify version agreement and
   this inventory before creating a versioned release tag.

Current `ci.yml` publishes qualification tags and `quality-evidence`; it does
not publish a versioned release or sign a PDF. Downstream consumers select
immutable qualified tags.

## Build integrity and provenance

`latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=paper paper/jankurai.tex`
builds from committed TeX and data. The required lane verifies a nonempty regular
`paper/jankurai.pdf` and records `target/jankurai/paper-build.sha256`. CI uploads
both. Bind the distributed PDF to that exact hash and selected source revision.
Bit-for-bit rebuilding additionally requires fixed TeX packages, fonts, and
timestamps; a successful build alone does not establish it.

The security lane requires fresh CycloneDX 1.6 from Syft, validates it against
pinned offline schemas, and scans it with Grype. The Node dependency lock is also
audited. A `tlmgr` listing is useful toolchain metadata but is not the required
validated CycloneDX inventory. A source-directory SBOM does not establish full
coverage of the runner's TeX installation; record that installation separately
in the release inventory.

Audit, proof, scanner, and failed-run artifacts remain in `quality-evidence`.
The public badge describes its linked audited revision with explicit source and
auditor provenance. Imported reports alone do not establish supervised execution
or release signing authority.

## Release gates and rollback

Require successful security and proof gates, reviewed source and artifact
inventory, and a verified restoration of the source backup before publication.
Monitor resulting-main checks and artifact hashes. Branch protection and
least-privilege publishing permissions are the abuse controls for this product.

If a release regresses, point consumers at the previous qualified immutable tag
and retained PDF. Preserve existing tags, assets, and failure evidence. Any
revert or correction goes through a new PR and full qualification before a new
release; rebuilding an old source tag must not silently replace its original PDF.
