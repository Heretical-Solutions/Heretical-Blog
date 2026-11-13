#!/usr/bin/env bash
#
# Production build of the static site into the ignored artifacts/site directory.
#
# Usage: eng/build.sh [--destination DIR]
#
# Jekyll runs with JEKYLL_ENV=production and without --drafts, so unapproved
# editorial material cannot reach the payload. Output stays inside this
# repository's ignored artifacts/ directory and never on the source branch.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

destination="$SITE_DIR"

while (($#)); do
  case "$1" in
  --destination)
    destination="$2"
    shift 2
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

export JEKYLL_ENV=production

rm -rf "$destination"

log "building production site into $destination"
bundle_run exec jekyll build --destination "$destination"

log "build complete"
