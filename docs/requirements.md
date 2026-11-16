# Requirements

Prerequisites for building, validating, and publishing this blog.

## Toolchain

| Requirement | Version | Enforcement | Notes |
|---|---|---|---|
| Ruby | `3.2.3` | `.ruby-version`; gem constraint `~> 3.1` | Verified here. Any `>= 3.1, < 4.0` satisfies the theme; other versions are untested and recorded in `compatibility.md` |
| Bundler | `4.0.6` | `Gemfile.lock` `BUNDLED WITH` | Writes and reads the lock's SHA-256 checksums |
| Jekyll | `4.4.1` | `Gemfile.lock` | Resolved from Chirpy's `~> 4.3` constraint |
| `jekyll-theme-chirpy` | `7.6.0` | `Gemfile` (`~> 7.6`) + lock | Packaged gem, never forked or vendored |
| `html-proofer` | `5.2.3` | lock, `:test` group | Validation only; not distributed |
| POSIX shell, GNU coreutils, `rsync` | current | `eng/` scripts | `rsync` stages the deployment payload |
| Git | `>= 2.42` | `eng/prepare-deployment.sh` | Needs `git worktree add --orphan` |

No global or system Ruby gem installation is required or permitted by the authoritative
commands. The bundle is isolated from system Ruby gems: `vendor/bundle` when the
repository path contains no whitespace, otherwise a directory outside it (default
`${BLOG_TMPDIR:-${TMPDIR:-/tmp}/heretical-blog}/heretical-blog-bundle`, override with `BLOG_BUNDLE_DIR`). See
[`docs/build.md`](build.md) for why a spaced bundle path breaks Bundler's `RUBYOPT` re-exec.

## Site configuration requirements

| Setting | Required value | Why |
|---|---|---|
| `url` | `https://heretical-solutions.github.io` | GitHub project Pages origin, no trailing slash |
| `baseurl` | `/Heretical-Blog` | Repository project path |
| `timezone` | `UTC` | Post dates and build timestamps |
| `lang` | `en` | Matches `_data/locales/en.yml` |
| `pwa.enabled` / `pwa.cache.enabled` | `false` | No installable or offline behaviour |
| `comments.provider` | empty | No comment system |
| `analytics.*.id` | empty | No analytics |
| `assets.self_host.enabled` | falsy | Nothing self-hosted is distributed; see `THIRD_PARTY_NOTICES.md` |

`eng/content-checks.rb` fails the build if any of these drift.

## External services

No external runtime service is required by the build itself. Woodpecker executes validation
on the trusted desktop `local-checks` agent through manual/cron triggers; live scheduling is an
operator acceptance gate.

- **RubyGems** is contacted by `eng/restore.sh` on a cold cache.
- **jsDelivr** and **Google Fonts** are contacted by the *visitor's browser* when browsing
  the published site, because front-end libraries and web fonts are CDN-referenced rather
  than self-hosted. Blocking them degrades appearance and search but does not affect the
  build.
- **GitHub** hosts the repository, the `gh-pages` branch, and Pages serving. Publishing and
  Pages settings are outside the build.

No credentials, tokens, webhooks, or service accounts participate in restore, build, or
validation.

## Inputs and outputs

| Kind | Path |
|---|---|
| Source of truth | `master` branch of this repository |
| Content inputs | `_posts/`, `_drafts/`, `_tabs/`, `_data/`, `_config.yml`, `_plugins/` |
| Generated payload | `artifacts/site/` (ignored) |
| Validation manifests | `artifacts/deployment-manifest-<sha>.txt`, `artifacts/deployment-commit-message.txt` (ignored) |
| Published output | `gh-pages` branch: static payload plus `.nojekyll` |

## Disclosure requirement

The published site is public. Nothing confidential, no credential, no private endpoint, and
no unreleased security information may enter `_posts/`. Repository visibility alone does not
make a Pages site private.
