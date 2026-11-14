#!/usr/bin/env bash
#
# Shared helpers for the blog's authoritative commands. Not meant to be run directly.

set -euo pipefail

log() {
  echo "eng: $*"
}

die() {
  echo "eng: $*" >&2
  exit 1
}

# Print the calling script's leading comment block as help text.
usage() {
  awk '
    NR == 1 { next }
    /^#[[:space:]]/ { sub(/^#[[:space:]]?/, ""); print; next }
    /^#[[:space:]]*$/ { print ""; next }
    { exit }
  ' "$0"
}

BLOG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$BLOG_ROOT"

ARTIFACTS_DIR="artifacts"
SITE_DIR="$ARTIFACTS_DIR/site"

# Bundler re-execs Ruby through RUBYOPT. Any gem path containing whitespace reaches that
# re-exec as separate arguments, so Ruby aborts with `invalid option`. Drop only the
# offending environment variables; the bundle resolved below stays authoritative.
for _var in GEM_HOME GEM_PATH; do
  _val="${!_var-}"
  if [[ "$_val" == *[[:space:]]* ]]; then
    log "ignoring $_var because its value contains whitespace; using the project-local bundle" >&2
    unset "$_var"
  fi
done
unset _var _val

# Deterministic, lock-driven restores. These override user and global configuration.
#
# Bundler also installs a copy of itself when the lockfile's BUNDLED WITH version is not
# the running one, and RUBYOPT then points at that copy. If the bundle path contains
# whitespace, every later `bundle exec` breaks. So when this repository lives under a path
# with spaces (the Heretical workspace does), the bundle is placed outside it. Override with
# BLOG_BUNDLE_DIR, which must itself be free of whitespace.
if [[ -n "${BLOG_BUNDLE_DIR-}" ]]; then
  BUNDLE_TARGET="$BLOG_BUNDLE_DIR"
  [[ "$BUNDLE_TARGET" != *[[:space:]]* ]] ||
    die "BLOG_BUNDLE_DIR must not contain whitespace: $BUNDLE_TARGET"
elif [[ "$BLOG_ROOT" == *[[:space:]]* ]]; then
  BUNDLE_TARGET="${BLOG_TMPDIR:-${TMPDIR:-/tmp}/heretical-blog}/heretical-blog-bundle"
  log "repository path contains whitespace; keeping the gem bundle outside it at $BUNDLE_TARGET" >&2
else
  BUNDLE_TARGET="vendor/bundle"
fi

export BUNDLE_PATH="$BUNDLE_TARGET"
export BUNDLE_FROZEN="true"

# Never enable shared-gem isolation: it forces the Bundler copy into the bundle path, and
# that copy is what breaks RUBYOPT whenever the path carries whitespace.
unset BUNDLE_DISABLE_SHARED_GEMS

bundle_run() {
  bundle "$@"
}

# Read a scalar from _config.yml. Uses stdlib YAML through plain Ruby so it works
# before the bundle is restored and never depends on a gem path.
config_value() {
  ruby -ryaml -e '
    path = ARGV.fetch(0)
    keys = ARGV.drop(1)
    abort "usage: config_value <file> <key>..." if keys.empty?
    data = YAML.safe_load_file(path, aliases: true)
    keys.each do |key|
      data = data.is_a?(Hash) ? data[key] : nil
    end
    print(data.to_s.strip)
  ' _config.yml "$@"
}

site_baseurl() {
  config_value baseurl
}
