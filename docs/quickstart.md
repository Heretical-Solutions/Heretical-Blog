# Quickstart

Minimal loop for writing and reviewing a post locally.

## First run

```sh
git clone https://github.com/Heretical-Solutions/Heretical-Blog.git
cd Heretical-Blog
eng/restore.sh
```

Ruby `3.2.3` is what this repository is verified against (`.ruby-version`). Use a version
manager if your system Ruby differs; the authoritative commands never install gems
globally.

## Preview

```sh
eng/serve.sh
```

Open <http://127.0.0.1:4000/Heretical-Blog/>. Drafts are included by default, so this is the
editorial preview. The base path matches production.

## Write a draft

```sh
cat > _drafts/2026-11-20-framework-progress.md <<'MD'
---
title: Framework progress note
date: 2026-11-20 09:00:00 +0000
categories: [Framework]
tags: [progress, diagnostics]
---

Keep the marker until a reviewer approves the text.
{: .prompt-warning }

What moved, why it moved, and what is still open. A merge is not a release.
MD
```

Rules the validator enforces:

- Filename `YYYY-MM-DD-<lowercase-slug>.md`, and the `date` must match that day and carry
  `+0000`.
- `title`, one or two `categories`, and at least one lowercase `tags` entry are required.
- Do not set `layout` or `permalink` per entry; site defaults own them.
- Drafts must carry the `EDITORIAL DRAFT` marker; published posts must not.

Preview it at `http://127.0.0.1:4000/Heretical-Blog/posts/framework-progress/` (drafts get
the same permalink as posts once promoted, minus the date-based URL differences Jekyll
applies to draft filenames).

## Validate before review

```sh
eng/validate.sh
```

This builds the production payload and proves that the draft is excluded while approved
posts are present. It also checks links, images, script references, front matter, and payload
hygiene.

## Publish

Publishing is a human decision, expressed as a file move:

```sh
git mv _drafts/2026-11-20-framework-progress.md _posts/2026-11-20-framework-progress.md
```

Remove the draft marker, edit for accuracy, then re-run `eng/validate.sh`. Commit and push to
`master` only when authorized; deployment to `gh-pages` is a separate, separately authorized
step described in `deployment.md`.

## Add an image, only if it explains the change

```sh
mkdir -p assets/posts/2026-11-20-framework-progress
# place an optimized screenshot here, then record origin/license in captions.md
```

Reference it as `/assets/posts/2026-11-20-framework-progress/inspector.png` with non-empty
alt text. The validator fails on unresolved media paths and empty alt text. Do not add stock
or generated illustrations.
