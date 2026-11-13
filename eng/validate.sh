#!/usr/bin/env bash
#
# Authoritative validation for the development blog.
#
# Usage: eng/validate.sh [--skip-build]
#
# Runs a production build, editorial/front-matter and source-metadata checks,
# internal link/asset checks through html-proofer with the project Pages base path,
# the draft-exclusion proof, and payload hygiene assertions.
#
# External links are not contacted: the CDN-hosted front-end libraries and outbound
# post links require network reachability that is not part of standalone validation.
# Publication-side checks (Pages settings, live URL) are documented in
# docs/deployment.md and cannot be completed from a source checkout.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

skip_build=false

while (($#)); do
  case "$1" in
  --skip-build)
    skip_build=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    die "unknown option: $1"
    ;;
  esac
done

baseurl="$(site_baseurl)"
[[ -n "$baseurl" ]] || die "baseurl must be set; html-proofer assertions depend on it"

status=0

if ! $skip_build; then
  log "step 1/5: production build"
  eng/build.sh || status=1
else
  log "step 1/5: skipping build (--skip-build)"
fi

[[ -d "$SITE_DIR" ]] || die "no production payload at $SITE_DIR"

log "step 2/5: editorial, configuration, and source-metadata checks"
ruby eng/content-checks.rb || status=1

log "step 3/5: internal links, images, and script references"
# Jekyll emits absolute paths that already include the project base path, while the
# payload root is the served root on gh-pages. Strip the base path and resolve
# against the payload directory so the check mirrors GitHub Pages.
bundle_run exec htmlproofer "$SITE_DIR" \
  --disable-external \
  --root-dir "$BLOG_ROOT/$SITE_DIR" \
  --swap-urls "^${baseurl}/:/" \
  --ignore-urls '/^http:\/\/127\.0\.0\.1/,/^http:\/\/0\.0\.0\.0/,/^http:\/\/localhost/' || status=1

log "step 4/5: draft exclusion and approved-post presence"
draft_slugs=()
while IFS= read -r file; do
  [[ -n "$file" ]] && draft_slugs+=("$(basename "$file" .md | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')")
done < <(find _drafts -maxdepth 1 -name '*.md' -print 2>/dev/null)

for slug in "${draft_slugs[@]}"; do
  if find "$SITE_DIR" -path "*/posts/$slug/index.html" -print -quit | grep -q .; then
    die "draft slug $slug was published to the production payload"
  fi
done

# A draft-only sentinel proves the exclusion assertion is not vacuous.
if grep -rqs "draft-exclusion-probe-7f3a9c" "$SITE_DIR"; then
  die "draft sentinel text found in the production payload"
fi
log "drafts excluded: ${#draft_slugs[@]} draft(s) checked, sentinel absent"

if [[ ${#draft_slugs[@]} -eq 0 ]]; then
  log "warning: no drafts present, so the exclusion proof is vacuous"
fi

approved=0
while IFS= read -r file; do
  slug="$(basename "$file" .md | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//')"
  if find "$SITE_DIR" -path "*/posts/$slug/index.html" -print -quit | grep -q .; then
    approved=$((approved + 1))
  else
    die "approved post $slug is missing from the production payload"
  fi
done < <(find _posts -maxdepth 1 -name '*.md' -print 2>/dev/null)
log "approved posts present in payload: $approved"

log "step 5/5: payload hygiene"
for forbidden in docs eng vendor Gemfile Gemfile.lock README.md AGENTS.md THIRD_PARTY_NOTICES.md .ruby-version _drafts artifacts .bundle; do
  if find "$SITE_DIR" -maxdepth 1 -name "$forbidden" -print -quit | grep -q .; then
    die "payload contains excluded input: $forbidden"
  fi
done

for required in index.html 404.html feed.xml sitemap.xml robots.txt \
  licenses/jekyll-theme-chirpy-LICENSE.txt licenses/chirpy-starter-LICENSE.txt licenses/bootstrap-LICENSE.txt; do
  if [[ ! -f "$SITE_DIR/$required" ]]; then
    die "payload is missing required output: $required"
  fi
done

if grep -rqs "CHANGE_ME\|your_full_name\|github_username\|twitter_username\|example@domain.com" "$SITE_DIR"; then
  die "payload still contains starter placeholder values"
fi

log "validation finished with status $status"
exit $status
