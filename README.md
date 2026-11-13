# Heretical Development Blog

Internal development-progress record for the Heretical workspace, built with
[Jekyll](https://jekyllrb.com/) and the [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy)
theme, published as a prebuilt static site on GitHub project Pages.

**Status:** initial implementation. Source is prepared on `master`; publication is manual
through a deployment-only `gh-pages` branch. No CI, webhook, or automatic draft generation
exists in this phase.

| Field | Value |
|---|---|
| Workspace path | `sites/blog/` |
| Canonical repository | <https://github.com/Heretical-Solutions/Heretical-Blog> |
| Source branch | `master` |
| Published site | <https://heretical-solutions.github.io/Heretical-Blog/> |
| License | MIT (see `LICENSE`) |

## Quick start

```sh
eng/restore.sh          # deterministic restore from Gemfile.lock into an isolated bundle
eng/serve.sh            # editorial preview with drafts at the project base path
eng/validate.sh         # production build plus content, link, and draft-exclusion checks
```

See [`docs/quickstart.md`](docs/quickstart.md) for the full first-run procedure.

## Documentation

| Document | Contents |
|---|---|
| [`docs/requirements.md`](docs/requirements.md) | Toolchain, external services, and prerequisites |
| [`docs/build.md`](docs/build.md) | Clean restore, build, validation, and build mode |
| [`docs/quickstart.md`](docs/quickstart.md) | Minimal local authoring and review loop |
| [`docs/editorial.md`](docs/editorial.md) | Draft queue, front matter, disclosure, and media rules |
| [`docs/deployment.md`](docs/deployment.md) | Manual static publication and rollback |
| [`docs/compatibility.md`](docs/compatibility.md) | Tested toolchain and dependency combinations |
| [`AGENTS.md`](AGENTS.md) | Agent instructions for this repository |
| [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) | Dependency inventory, licenses, and distributed notices |

## Layout

```text
.
├── _config.yml          # Site identity and the project Pages url/baseurl
├── _data/               # Contact links, share platforms, and UI-string overrides
├── _drafts/             # Drafts awaiting editorial review; excluded from production
├── _plugins/            # Local Jekyll hooks
├── _posts/              # Reviewed, published posts
├── _tabs/               # About, categories, tags, archives
├── assets/img/favicons/ # Product-owned icon set
├── docs/                # Product documentation
├── eng/                 # Restore, serve, build, validate, and deployment preparation
├── licenses/            # Upstream license texts distributed with the static payload
└── artifacts/           # Generated site, reports, and staged payloads; ignored
```

## Editorial model

`_drafts/` is the single draft queue. A human reviewer promotes approved content into
`_posts/`; production builds exclude drafts, so unreviewed material cannot reach the
published site. A merge is not a release, and this repository publishes no confidential
material: the published site is public.
