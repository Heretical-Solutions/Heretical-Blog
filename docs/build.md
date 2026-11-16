# Build

Standalone build mode: this repository builds from its own canonical clone using the
committed `Gemfile.lock`. It consumes no other Heretical product and needs no workspace
checkout layout.

## Clean restore

```sh
eng/restore.sh            # install the locked set and verify it
eng/restore.sh --clean    # discard the existing bundle and .bundle first
```

What it guarantees:

- `BUNDLE_PATH` is project-local and `BUNDLE_FROZEN` is set, so restore cannot resolve new
  versions silently.
- `BUNDLE_DISABLE_SHARED_GEMS` is deliberately **not** enabled. It makes Bundler install a
  copy of itself into the bundle, and `RUBYOPT` then points at that copy.
- Restore fails if `Gemfile.lock` is absent, because a lock-less resolve is not
  reproducible.
- `bundle check` confirms the lock is satisfied, and a `bundle exec` smoke test confirms the
  bundle is actually runnable.

### Bundle location and the whitespace hazard

This workspace path contains spaces (`Heretical Development`), and Bundler re-execs Ruby
through `RUBYOPT`, where any whitespace-containing gem path is split into separate arguments
so Ruby aborts with `invalid option`. Two independent triggers exist; `eng/lib/common.sh`
handles both:

| Trigger | Symptom | Handling |
|---|---|---|
| A user gem path containing whitespace, e.g. `GEM_HOME=/path with spaces/gems` | `ruby3.2: invalid option -g` | `GEM_HOME`/`GEM_PATH` are dropped when their value contains whitespace, with a diagnostic |
| The bundle path itself containing whitespace, which also occurs when Bundler copies itself into it | `ruby3.2: invalid option -D` after a clean restore | When the repository path has whitespace the bundle is placed outside it at `${BLOG_TMPDIR:-${TMPDIR:-/tmp}/heretical-blog}/heretical-blog-bundle`; override with `BLOG_BUNDLE_DIR`, which must be whitespace-free |

On this machine restored gems live under the product-specific temporary bundle directory instead of
`vendor/bundle`, and nothing is installed globally or into a shared gem path. In a checkout
whose path has no whitespace the bundle stays at the ignored `vendor/bundle`.
`eng/restore.sh` prints the resolved location on every run.

## Production build

```sh
eng/build.sh
```

Runs `JEKYLL_ENV=production bundle exec jekyll build --destination artifacts/site` after
removing the previous payload. It never passes `--drafts`, so unapproved editorial material
cannot reach the payload, and `compress_html` stays active in production.

Generated output goes only to ignored paths. The authoritative deployable destination is
`artifacts/site`; `_site/` stays ignored because it is Jekyll's default destination if someone
runs bare `jekyll serve` outside these commands.

## Local preview

```sh
eng/serve.sh                     # drafts on, development mode
eng/serve.sh --no-drafts         # what production will look like
eng/serve.sh --production        # production mode, drafts still served for review
eng/serve.sh --host 0.0.0.0 --port 4001
```

The server listens at `http://127.0.0.1:4000/Heretical-Blog/` — the same base path GitHub
Pages serves, so relative URLs behave as they will in production. Preview output goes to the
ignored `artifacts/preview`, keeping every generated tree under one root and separate from
the deployable `artifacts/site` payload.

## Validation

```sh
eng/validate.sh                  # build, then all checks
eng/validate.sh --skip-build     # reuse the current artifacts/site payload
```

Five steps, all of which must pass:

1. **Production build** as above.
2. **`eng/content-checks.rb`** — configuration and hygiene assertions plus per-entry
   editorial rules: filename/slug form, explicit `+0000` date matching the filename and not
   in the future, required `title`/`categories`/`tags`, no per-entry `layout` or `permalink`
   override, comments disabled, draft marker present in `_drafts/` and absent from
   `_posts/`, generated-note source metadata with the
   public lowercase editorial idempotency key, editorial approval on any
   generated note already published, media references resolving to committed files, non-empty
   alt text, unique slugs, and at least one published post.
3. **`html-proofer`** — internal links, images, and script references with
   `--disable-external`, `--root-dir artifacts/site`, and
   `--swap-urls '^/Heretical-Blog/:/'`. Jekyll emits absolute paths that already contain the
   project base path while the payload root is the served root, so the base path must be
   stripped before files are resolved. Note that `--swap-urls` patterns are handed to
   `Regexp.new` **without** slash delimiters: writing `/^\/Heretical-Blog/:/` silently matches
   nothing and produces hundreds of false failures.
4. **Draft exclusion proof** — every `_drafts/` slug is asserted absent from the payload, the
   sentinel string `draft-exclusion-probe-7f3a9c` is asserted absent, and every `_posts/`
   slug is asserted present. With no drafts the run warns that the proof is vacuous.
5. **Payload hygiene** — excluded inputs (`docs`, `eng`, `vendor`, `Gemfile`,
   `Gemfile.lock`, `README.md`, `AGENTS.md`, `THIRD_PARTY_NOTICES.md`, `.ruby-version`,
   `_drafts`, `artifacts`, `.bundle`) are absent; required outputs (`index.html`,
   `404.html`, `feed.xml`, `sitemap.xml`, `robots.txt`, `LICENSE`, and both
    `licenses/*.txt`, including Chirpy Starter) are present; and no starter placeholder value survives.

## Woodpecker workflows

`.woodpecker/restore-validate.yaml` calls the same clean restore and full validation commands
on the `local-checks` agent. `.woodpecker/prepare-deployment.yaml` calls
`eng/prepare-deployment.sh --dry-run "${CI_COMMIT}"` and publishes nothing. Initial triggers
are manual/cron only; local command evidence does not claim a live agent run.

## Dependency-order and integration builds

There is no cross-product build. The superproject registers this repository as a submodule
and validates it through this repository's own commands from a clean recursive checkout.

## Failure modes worth recognising

| Symptom | Cause |
|---|---|
| `ruby3.2: invalid option -g` | A user gem path containing whitespace reached `RUBYOPT`; use the `eng/` commands, which handle it |
| `ruby3.2: invalid option -D` after `--clean` | The bundle path itself contains whitespace; the `eng/` commands relocate it outside a spaced repository path |
| Hundreds of "does not exist" internal failures | Base path not stripped before resolving payload files, or a slash-delimited `--swap-urls` pattern |
| `Could not find ... in locally installed gems` | Restore not run, or `--clean` removed `vendor/bundle` since |
| `fatal: ambiguous argument 'HEAD'` during build | A Git-history-less checkout; the guarded `_plugins/posts-lastmod-hook.rb` suppresses it |
| Deployment worktree reports nothing to stage | The worktree sits inside an ignored path of the working tree; move it outside with `--deploy-dir` |
