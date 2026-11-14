# Deployment

Manual static publication. This document is the authoritative procedure; the workspace's
general Actions-based Pages policy is deliberately overridden for this blog by an approved
interim decision, and the superproject alignment happens at the registration gate.

## Output identity

| Field | Value |
|---|---|
| Artifact | Prebuilt static site: HTML, CSS, JS, images, feeds, sitemap, license texts |
| Branch | `gh-pages` (deployment-only; contains no source) |
| Host | GitHub project Pages |
| URL | `https://heretical-solutions.github.io/Heretical-Blog/` |
| Serving path | Payload root == `/Heretical-Blog/` |
| Processing | Disabled: `.nojekyll` at the payload root, so GitHub performs no Jekyll build |

There is no custom domain, CNAME, DNS record, or certificate to manage. GitHub issues and
renews the `github.io` certificate.

## Prerequisites

- A clean, reviewed `master` source revision that is **pushed and canonically available**.
  Never deploy a commit that exists only locally.
- Git `>= 2.42` for `git worktree add --orphan`.
- Network reachability to RubyGems for restore. No deployment credentials participate in
  building or validating.
- Push permission to `gh-pages` and Pages administration rights in the repository settings,
  held by the user.

## Procedure

### 1. Build and validate the candidate revision

```sh
git fetch origin
git checkout <reviewed-master-sha>       # detached is fine
git status --porcelain -uall             # must be empty
eng/restore.sh --clean
eng/validate.sh
```

`eng/validate.sh` must pass, including the draft-exclusion proof and payload hygiene.

### 2. Prepare the deployment payload

```sh
eng/prepare-deployment.sh --dry-run <reviewed-master-sha>   # optional rehearsal
eng/prepare-deployment.sh <reviewed-master-sha>
```

What it does:

- Refuses unless the working tree is clean and checked out at the selected revision, and
  unless that revision contains `_config.yml` (which rejects a `gh-pages` payload commit).
- Re-runs restore, the production build, and the full validation.
- Writes a per-file SHA-256 manifest and a commit-message template into `artifacts/`.
- Creates or reuses the `gh-pages` worktree **outside** this working tree — default
  `${BLOG_TMPDIR:-${TMPDIR:-/tmp}/heretical-blog}/heretical-blog-gh-pages`, override with `--deploy-dir` or
  `BLOG_DEPLOY_DIR` — and stages only the payload plus `.nojekyll`, protecting the
  worktree's `.git` file during staging.
- Asserts the staged payload is actually stageable, then prints the source SHA, the commit
  message, and the worktree status.
- **Stops.** It commits nothing and pushes nothing.

The worktree must live outside the repository working tree. A worktree nested under an
ignored path such as `artifacts/` inherits the repository ignore rules, so `git add -A`
would stage nothing and Git would treat the worktree as prunable.

### 3. Review, then obtain authorization

Inspect the printed status and confirm:

- Only generated content: HTML pages, `assets/`, `feed.xml`, `sitemap.xml`, `robots.txt`,
  `404.html`, the product `LICENSE`, `licenses/`, and `.nojekyll`.
- No `docs/`, `eng/`, `Gemfile*`, `README.md`, `AGENTS.md`, `THIRD_PARTY_NOTICES.md`,
  `_drafts/`, `vendor/`, or `.bundle/`.
- The recorded source SHA matches the reviewed `master` commit.

Publication authorization is separate from source authorization.

### 4. Commit and push the deployment

```sh
git -C <deploy-dir> status --short -uall
git -C <deploy-dir> add -A
git -C <deploy-dir> commit -F <source-checkout>/artifacts/deployment-commit-message.txt
git push origin gh-pages
```

The commit message records the exact source revision, base path, build and validation
commands, payload size, and manifest path, so every deployment stays traceable to a source
commit.

### 5. Configure Pages (user action, once)

Repository **Settings → Pages → Source → Deploy from a branch**, branch `gh-pages`,
directory `/ (root)`, save. GitHub then serves
`https://heretical-solutions.github.io/Heretical-Blog/`.

## Smoke tests after publication

- Home page renders at the project URL with sidebar title and tagline.
- The approved post opens at `/Heretical-Blog/posts/<slug>/`.
- Navigation: About, Categories, Tags, Archives.
- Search returns the approved post; categories and tag pages resolve.
- Atom feed at `/Heretical-Blog/feed.xml` and `sitemap.xml` use the full project URL.
- Assets load (no 404 in the network panel); code blocks are highlighted; TOC anchors work.
- Light/dark toggle and responsive layout behave; no browser-console errors where practical.
- `/Heretical-Blog/licenses/jekyll-theme-chirpy-LICENSE.txt`,
  `/Heretical-Blog/licenses/chirpy-starter-LICENSE.txt`, and
  `/Heretical-Blog/licenses/bootstrap-LICENSE.txt` are reachable.
- Draft content and the sentinel string are absent from the live site.

These checks require the live URL and cannot be completed from a source checkout. Record them
as pending until someone runs them.

## Traceability

| Direction | Mechanism |
|---|---|
| Deployment → source | Source SHA in the deployment commit message and manifest file name |
| Source → deployment | `git log gh-pages -- <path>` and the manifest's per-file hashes |
| Reproduce | Check out the recorded source SHA, run `eng/restore.sh --clean && eng/build.sh`, compare against `artifacts/deployment-manifest-<sha>.txt` |

The superproject gitlink must point at the blog **source** commit on `master`, never at a
`gh-pages` deployment commit.

## Rollback

Rollback is a `gh-pages` history operation; `master` is unaffected.

```sh
git -C <deploy-dir> log --oneline            # find the last known-good deployment
git -C <deploy-dir> reset --hard <deployment-sha>
git push --force-with-lease origin gh-pages
```

Because GitHub Pages serves the branch tip, the previous site returns once propagation
finishes. `--force-with-lease` is mandatory; a plain force-push can clobber an unseen
deployment.

Preferred forward fix when the source is at fault: revert or correct `master`, re-run this
procedure, and record the new source SHA. Immediate mitigation when the payload is at fault:
roll `gh-pages` back first, then fix forward.

Backup: the payload is fully reproducible from any source revision, so no separate artifact
store is required. Keep the deployment history on `gh-pages` as the operational record.

## Secrets and permissions

- No credential, token, or secret participates in restore, build, validation, or staging.
- Remote URLs must be credential-free. Never use a token-bearing remote.
- No Actions secrets, deployment environments, protected environments, or webhooks exist in
  this phase.
- Push and Pages-settings rights remain with the user.

## Explicitly not deployed

No `.github/workflows/`, no CI status checks, no automatic draft generation, no custom
domain, no analytics, no comment system, no PWA/service-worker registration, and no
self-hosted third-party front-end assets. Build/deploy automation and event-driven drafts
each remain separate later proposals requiring their own approval; this procedure does not
imply either.
