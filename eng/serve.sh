#!/usr/bin/env bash
#
# Local preview server for editorial review.
#
# Usage: eng/serve.sh [--host HOST] [--port PORT] [--no-drafts] [--production]
#
# Drafts are served by default because this command exists for editorial review.
# The site is reachable under the repository baseurl, exactly as GitHub project
# Pages will serve it. Preview output stays under the ignored artifacts/ directory,
# and this server never writes to the deployment payload.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

host="127.0.0.1"
port="4000"
drafts=true
production=false

while (($#)); do
  case "$1" in
  --host)
    host="$2"
    shift 2
    ;;
  --port)
    port="$2"
    shift 2
    ;;
  --no-drafts)
    drafts=false
    shift
    ;;
  --production)
    production=true
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

args=(exec jekyll serve --host "$host" --port "$port" --destination artifacts/preview --watch --incremental)
if $drafts; then
  args+=(--drafts)
fi

if $production; then
  export JEKYLL_ENV=production
  log "serving in production mode (JEKYLL_ENV=production)"
fi

log "preview at http://$host:$port$(site_baseurl)/"
bundle_run "${args[@]}"
