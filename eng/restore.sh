#!/usr/bin/env bash
#
# Clean, deterministic dependency restore from the committed Gemfile.lock.
#
# Usage: eng/restore.sh [--clean]
#   --clean   discard the existing bundle before restoring
#
# Gems install into the bundle path resolved by eng/lib/common.sh: vendor/bundle when the
# repository path has no whitespace, otherwise a product-specific temporary directory.
# Nothing is installed globally or into the system Ruby gem path.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

clean=false

while (($#)); do
  case "$1" in
  --clean)
    clean=true
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

[[ -f Gemfile.lock ]] || die "Gemfile.lock is missing; restore is lock-driven and must not resolve new versions silently"

if $clean; then
  log "removing the existing bundle at $BUNDLE_TARGET"
  rm -rf "$BUNDLE_TARGET"
  rm -rf .bundle
fi

log "restoring the locked dependency set into $BUNDLE_TARGET"
bundle_run install --jobs 4 --retry 3

# Smoke-test the re-exec path itself. A gem path containing whitespace, or a Bundler copy
# inside such a path, breaks every later `bundle exec` with `invalid option`.
if ! smoke="$(bundle_run exec ruby -e 'print "ok"' 2>&1)"; then
  die "the restored bundle cannot be executed; check for whitespace in BUNDLE_PATH ($BUNDLE_TARGET) or in GEM_HOME/GEM_PATH:
$smoke"
fi

bundle_run check

log "restore complete"
