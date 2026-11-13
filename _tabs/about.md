---
icon: fas fa-info-circle
order: 4
---

This site is the internal development-progress record for **Heretical Development**,
the workspace that composes the Heretical products, sites, and infrastructure
deployments from exact, individually versioned repositories.

## What it records

- Concise notes on meaningful merged work and project progress.
- Design decisions and their constraints, when the record is more useful than the
  architecture decision document it accompanies.
- Experiments, milestones, and release or milestone summaries.

It does not replace product documentation, changelogs, release notes, planning cards,
or the documentation portal. Those remain authoritative in their owning repositories;
posts here link to them instead of duplicating them.

## What it is not

A merge is not a release. Posts distinguish merged, unreleased work from functionality
available in a published version, and routine maintenance is summarised or omitted at
the discretion of the reviewer.

"Internal" describes the editorial purpose, not access control. The site is hosted on
public GitHub Pages, so nothing confidential belongs in a post.

## Editorial process

Posts are authored and promoted by hand. Unapproved material lives in `_drafts/` and is
excluded from production builds; a human reviewer moves approved content into `_posts/`.
There is no event-driven draft generation and no continuous deployment in this initial
phase. See `docs/editorial.md` in the source repository.

## Source, license, and hosting

- Source: <https://github.com/Heretical-Solutions/Heretical-Blog> (branch `master`).
- Publication: a locally built static payload on the deployment-only `gh-pages` branch,
  served by GitHub project Pages under `/Heretical-Blog/`.
- License: the site source and the authored posts are MIT. Exact dependency licenses and
  notices are in `LICENSE`, `THIRD_PARTY_NOTICES.md`, and `licenses/` of the source
  repository, and the license texts for the code compiled into the published bundles are
  distributed alongside the site at
  [`/Heretical-Blog/licenses/jekyll-theme-chirpy-LICENSE.txt`]({{
  '/licenses/jekyll-theme-chirpy-LICENSE.txt' | relative_url }}) and
  [`/Heretical-Blog/licenses/bootstrap-LICENSE.txt`]({{
  '/licenses/bootstrap-LICENSE.txt' | relative_url }}).
- Front-end libraries are loaded from a public CDN rather than bundled, and no analytics,
  comments, or offline caching is enabled.
