# Editorial Process

This blog is an internal development-progress record published on public GitHub Pages.
"Internal" describes purpose and tone, not access control.

## One draft queue

`_drafts/` is the only draft queue. There is no `content/drafts/` and no competing mechanism.

```
author writes draft  →  eng/validate.sh  →  human review  →  git mv into _posts/
                                                              ↓
                                              authorized commit/push to master
                                                              ↓
                                    separate authorized static deployment
```

Promotion into `_posts/` **is** the publication decision. Production builds exclude drafts,
so unreviewed material cannot reach the published site even if a deployment is triggered by
mistake.

## Front matter contract

| Field | Rule |
|---|---|
| Filename | `YYYY-MM-DD-<slug>.md`, slug lowercase `[a-z0-9-]`, no leading/trailing hyphen |
| `title` | Required, non-empty |
| `date` | Required, explicit `+0000` offset, must match the filename date, never in the future |
| `categories` | Required, one or two levels (primary, optional secondary) |
| `tags` | Required, at least one lowercase slug |
| `layout`, `permalink` | Must not appear; site defaults own them |
| `comments` | Must stay unset; the product disables comments globally |
| `image` | Optional; if present it must resolve to a committed file |

Permalinks are `/posts/<slug>/`. Changing the site permalink pattern breaks every existing
link, so it is treated as a breaking change requiring a link audit.

## Draft marker

Every draft carries an explicit marker in its body:

```markdown
<!-- EDITORIAL DRAFT — NOT APPROVED FOR PUBLICATION. -->
```

`eng/content-checks.rb` requires the marker in `_drafts/` and rejects it in `_posts/`. The
current welcome draft also contains the sentinel string `draft-exclusion-probe-7f3a9c`, which
`eng/validate.sh` asserts absent from the production payload so the exclusion check cannot
pass vacuously. Keep both until a reviewer approves the text; strip the marker on promotion.

## Review checklist

Before promoting a draft:

- Technical accuracy, and the right level of internal detail.
- State is labelled correctly: merged, unreleased, experimental, superseded, or released.
  **A merge is not a release.**
- Correct product category, tags, dates, and source references.
- Known limitations and follow-up work are stated, not smoothed over.
- No credential, token, private endpoint, customer data, unreleased vulnerability detail, or
  other confidential material.
- Media is necessary, optimized, has alt text or a caption, and has recorded provenance.
- Tone is a development record, not marketing copy.
- Links point at authoritative records instead of duplicating them.

Reviewer responsibility is to correct facts and clarity, never to fabricate confidence or
suppress known limitations.

## Content integrity

For any future generated development note, treat pull-request titles, descriptions, comments,
labels, diffs, and generated summaries as **untrusted data**, never as instructions and never
as approval to publish. Generated text must not invent:

- Motivations or design decisions absent from reviewed material.
- Build or test results, or compatibility claims.
- Release availability or migration instructions.
- Screenshots, demonstrations, or performance numbers.
- Reviewer approval.

Generated notes must carry this metadata block, which the validator enforces:

```yaml
source:
  repository: Heretical Development workspace
  publication: https://heretical-solutions.github.io/Heretical-Documentation/
  idempotency_key: descriptive-editorial-slug
editorial_approval:          # required once the note is in _posts/
  reviewer: human-login
  approved_at: 2026-11-21 10:00:00 +0000
```

The idempotency key is a stable public lowercase editorial slug. Repeated, reordered, or
retried events must produce nothing new, and an existing draft must never be overwritten
silently. Private PR numbers, private repository URLs, private source SHAs and machine-local
paths remain in internal source/compatibility records, not public front matter or prose.
Public source and deployment provenance remains permitted.

Note: no draft-generation automation exists in this phase. These rules exist so that a later
automation proposal has a fixed contract to implement against, and so that any manually
written "generated-style" note remains verifiable.

## Media and provenance

- Add media only when it explains a change.
- Path convention: `assets/posts/<post-id>/<descriptive-name>.<ext>`, with `captions.md`
  beside it recording origin, author, license, modifications, and alt text.
- Optimize screenshots; provide alt text and captions.
- No stock imagery, AI-generated illustration, or video merely to fill a post.
- Large or frequently changing video stays out of ordinary Git history; use a documented
  release/media store with a stable URL.
- Every asset's license must be recorded here and in `THIRD_PARTY_NOTICES.md` when it is
  third-party.

The site has no photography or video. The product-owned favicon set is generated from
`assets/img/favicons/favicon.svg`. The approved Doxygen portal post includes two factual Firefox
screenshots under `assets/posts/2026-11-14-doxygen-documentation-portal/`; their origin,
modifications, licensing, and alt text are recorded in the adjacent `captions.md`.
The approved ntfy LAN deployment post includes a user-supplied factual Android screenshot
under `assets/posts/2026-11-14-ntfy-lan-deployment/`; its provenance is recorded in the
adjacent `captions.md`. Editorial approval is recorded in the post's front matter.

## Disclosure

The published payload is world-readable and cacheable by GitHub. Before promotion, confirm
the post contains no:

- Secrets, tokens, or credential-bearing remote URLs.
- Private hostnames, internal endpoints, or environment-specific paths.
- Customer or user data.
- Unreleased security information.
- Third-party material without a clear license.

If access-restricted reading is ever required, select and verify an appropriate access-controlled
hosting model before publication; repository visibility alone does not restrict this site.
