# Compatibility

Compatibility records for this website product. Versions come from `Gemfile.lock`; this file
states what was actually tested rather than what is theoretically supported.

## Tested combination

| Input | Version | Status |
|---|---|---|
| Operating system | Ubuntu 24.04 LTS, Linux `x86_64-linux-gnu` | Tested |
| Ruby | 3.2.3 (patchlevel 157) | Tested |
| RubyGems | 3.4.20 | Tested |
| Bundler | 4.0.6 | Tested; writes the committed lock with SHA-256 checksums |
| Jekyll | 4.4.1 | Tested |
| `jekyll-theme-chirpy` | 7.6.0 | Tested |
| `html-proofer` | 5.2.3 | Tested |
| Git | 2.43.0 | Tested, including `git worktree add --orphan` |
| Node/npm | not used | Not required |
| Container runtime | Docker 29.1.3 with pinned `ruby:3.2.3-bookworm` image `sha256:9ee6e94a…d1be9` | Clean restore, full validation, and non-publishing deployment dry run tested |

Validated with this combination: clean restore, production build, content checks,
`html-proofer` internal checks over 13 HTML files and 27 internal links, draft-exclusion
proof, payload hygiene, and the full deployment-preparation flow in a throwaway repository
copy (orphan worktree creation, payload staging, stale-file deletion on refresh, and every
safety gate).

Additional Woodpecker container evidence on 2026-11-15: the pinned Ruby image completed
clean restore and full validation over **23 HTML files and 46 internal links**, and
`eng/prepare-deployment.sh --dry-run 8b5da68569b322d2dac24970acacbf470a4a7580` completed
from a clean clone with a payload manifest and no deployment commit or push. These are
local container results, not a claim that a live Woodpecker agent has run.

Two whitespace-related restore hazards were found and fixed on this host, and both are
documented in `docs/build.md`: a user `GEM_HOME` containing whitespace, and the repository
path itself containing whitespace. The first is handled by dropping the offending variable;
the second relocates the gem bundle outside the working tree. A fresh checkout with a
space-free path was verified to keep the bundle at `vendor/bundle`.

## Supported ranges

| Input | Range | Basis |
|---|---|---|
| Ruby | `>= 3.1, < 4.0` | Theme's `required_ruby_version` constraint `~> 3.1`. Only 3.2.3 is verified here |
| Jekyll | `~> 4.3` | Theme constraint; resolved to 4.4.1 |
| Chirpy | `~> 7.6` | `Gemfile` constraint; resolved to 7.6.0 |
| Platforms | `x86_64-linux-gnu` verified | Lock covers `aarch64-linux-*`, `arm-linux-*`, `*-darwin`, `x86_64-linux-musl` |
| Windows / JRuby | Not verified | `Gemfile` keeps the starter's `tzinfo`/`tzinfo-data`/`wdm` shims; native gems and `eng/` scripts are untested there |

## Site contract compatibility

| Aspect | Value | Notes |
|---|---|---|
| Published URL | `https://heretical-solutions.github.io/Heretical-Blog/` | Project Pages; requires the repository name to remain `Heretical-Blog` |
| `url` / `baseurl` | `https://heretical-solutions.github.io` / `/Heretical-Blog` | Changing the repository name or org breaks every absolute URL and the sitemap/feed; a rename is a breaking change |
| Permalink pattern | `/posts/:title/` | Treat as a public contract |
| Timezone | UTC | Post dates must carry `+0000` |
| Language | `en` | `_data/locales/en.yml` overrides the theme's UI strings |
| Content encoding | UTF-8 Markdown via Kramdown/GFM | Syntax highlighting through Rouge; Mermaid available from the CDN |

## Feature matrix

| Feature | State |
|---|---|
| Search, categories, tags, archives | Enabled (theme-provided) |
| Atom feed, sitemap, robots | Enabled |
| Syntax highlighting, TOC, light/dark, responsive layout | Enabled |
| Comments | Disabled globally |
| Analytics and page views | Disabled |
| PWA / offline caching / service worker | Disabled (`pwa.enabled: false`; `sw.min.js` is still emitted by the theme but never registers) |
| Third-party share links | Disabled (`_data/share.yml` platforms empty); local copy-link remains |
| Self-hosted front-end assets | Disabled; libraries load from jsDelivr |
| Avatar, CDN media, social preview image | Not configured |
| CI/CD | Woodpecker restore/validation and non-publishing preparation workflows implemented; live scheduling pending. No GitHub Actions workflow or automatic publication |
| Webhooks, automatic drafts | Absent by design in this phase |

## Browser expectations

Chirpy 7.6.0 targets current evergreen browsers; its bundles use ES modules
(`assets/js/dist/*.min.js`) and CSS custom properties for light/dark mode. No specific
browser matrix was executed for this initial delivery; the responsive layout and theme
toggle are verified only through generated output and link/asset checks, not by driving a
browser. Blocking jsDelivr or Google Fonts degrades styling and search but does not break
content delivery.

## Known limitations and unverifiable checks

| Item | Status |
|---|---|
| Live Pages URL, asset loading, console errors | Pending: requires the `gh-pages` push and Pages settings (later stages) |
| Ruby 3.4 and other Ruby versions | Untested; the constraint allows them |
| macOS/Windows builds | Untested |
| Live Woodpecker execution | Pending repository/agent acceptance; local container validation is not a scheduled pipeline result |
| External link liveness | Not checked; validation runs with `--disable-external` |
| CDN-pinned majors (`@1`, `@4`, `@7`) | Floating upstream majors; a breaking upstream release could alter browse-time behaviour without any change in this repository |
| Search index | `assets/js/data/search.json` is generated and validated only as a file; search interaction is untested |

## Release and versioning

This product has no package version and publishes no library artifact. Its versions are Git
revisions: `master` for source, `gh-pages` for deployments, with each deployment commit
recording its source SHA. Superproject tags will identify tested combinations once the blog
is registered as a submodule.

## Change rules

- A dependency or toolchain change updates `Gemfile.lock`, this file, and
  `THIRD_PARTY_NOTICES.md` in the same commit, with `eng/validate.sh` passing from a clean
  restore.
- A theme upgrade is a compatibility change: re-check the locale override, favicon
  replacements, hook guard, `_config.yml` keys, distributed license texts, and the payload
  hygiene list, because upstream may have changed any of them.
- A URL, base path, or permalink change is breaking and needs a link audit plus updated
  workspace documentation.
