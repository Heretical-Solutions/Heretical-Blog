#!/usr/bin/env bash
#
# Prepare the deployment-only gh-pages payload for an explicitly selected source revision.
#
# Usage: eng/prepare-deployment.sh [--dry-run] <source-ref>
#
# <source-ref> is required and is never defaulted. The working tree must be clean and
# checked out at that revision, so the payload is provably built from reviewed source.
#
# This command restores the locked dependencies, runs the same production build and
# validation as local review, stages only the generated static payload plus .nojekyll,
# and records the exact source revision for the deployment commit message.
#
# It STOPS before any deployment commit or push. Committing and pushing gh-pages needs
# separate authorization; see docs/deployment.md.
#
#   --dry-run   stage the payload under artifacts/deployment-stage and print the gated
#               Git commands without creating or touching any branch or worktree
#   --deploy-dir PATH
#               deployment worktree location. It must live OUTSIDE this working tree:
#               a worktree nested under an ignored directory such as artifacts/ inherits
#               the repository ignore rules, so the payload would stage as nothing and
#               Git would consider the worktree prunable.
#
# Generated HTML is staged outside the source working tree (or under ignored artifact
# paths in --dry-run). It never becomes source on the master branch.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

DEPLOY_BRANCH="gh-pages"
STAGE_PATH="artifacts/deployment-stage"
MESSAGE_PATH="artifacts/deployment-commit-message.txt"
DEPLOY_DIR="${BLOG_DEPLOY_DIR:-${BLOG_TMPDIR:-${TMPDIR:-/tmp}/heretical-blog}/heretical-blog-gh-pages}"

dry_run=false
ref=""

while (($#)); do
  case "$1" in
  --dry-run)
    dry_run=true
    shift
    ;;
  --deploy-dir)
    DEPLOY_DIR="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    die "unknown option: $1"
    ;;
  *)
    [[ -z "$ref" ]] || die "only one source revision may be selected; got '$ref' and '$1'"
    ref="$1"
    shift
    ;;
  esac
done

[[ -n "$ref" ]] || die "an explicit <source-ref> is required; this helper never infers what to deploy"
[[ -d .git ]] || die "this repository must be a Git checkout to record deployment provenance"

requested_dir="$DEPLOY_DIR"
case "$requested_dir" in
/*) ;;
*) requested_dir="$BLOG_ROOT/$requested_dir" ;;
esac
reject_nested() {
  case "$1/" in
  "$BLOG_ROOT"/*)
    die "the deployment worktree must not live inside the source working tree ($1). A worktree under an ignored path inherits the repository ignore rules, so the payload would stage as nothing. Use --deploy-dir or BLOG_DEPLOY_DIR."
    ;;
  esac
}
reject_nested "$requested_dir"
mkdir -p "$requested_dir"
DEPLOY_DIR="$(cd "$requested_dir" && pwd -P)"
reject_nested "$DEPLOY_DIR"
log "deployment worktree: $DEPLOY_DIR"

for op in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG; do
  [[ -e ".git/$op" ]] && die "an in-progress Git operation was detected (.git/$op); resolve it first"
done

log "resolving selected source revision: $ref"
source_sha="$(git rev-parse --verify --quiet "${ref}^{commit}")" || die "cannot resolve '$ref' to a commit"

head_sha="$(git rev-parse HEAD)"
[[ "$head_sha" == "$source_sha" ]] ||
  die "HEAD ($head_sha) is not the selected revision ($source_sha); check out the revision you intend to deploy"

dirty="$(git status --porcelain=v1 -uall)"
[[ -z "$dirty" ]] || die "working tree is not clean; commit or discard these changes before deploying:
$dirty"

# A source revision carries site configuration. This rejects a gh-pages payload commit.
git cat-file -e "${source_sha}:_config.yml" 2>/dev/null ||
  die "$source_sha has no _config.yml; it is a deployment payload, not a blog source revision"

baseurl="$(site_baseurl)"
log "selected source revision: $source_sha"
log "project Pages base path:  $baseurl"

log "restoring locked dependencies"
eng/restore.sh

log "running production build and full validation"
eng/validate.sh

[[ -d "$SITE_DIR" ]] || die "validation did not leave a payload at $SITE_DIR"

short_sha="$(git rev-parse --short=12 "$source_sha")"
manifest_rel="artifacts/deployment-manifest-${short_sha}.txt"
(
  cd "$SITE_DIR"
  find . -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum
) >"$manifest_rel"
payload_files="$(wc -l <"$manifest_rel")"
payload_bytes="$(du -sb "$SITE_DIR" | cut -f1)"

cat >"$MESSAGE_PATH" <<MSG
Publish static site from ${source_sha}

Source revision: ${source_sha}
Base path:       ${baseurl}
Build:           eng/build.sh (JEKYLL_ENV=production, drafts excluded)
Validation:      eng/validate.sh
Payload:         ${payload_files} files, ${payload_bytes} bytes
Manifest:        ${manifest_rel} (SHA-256 per file, sorted by path)
MSG

log "prepared payload: $payload_files files, $payload_bytes bytes; manifest $manifest_rel"
log "commit message template: $MESSAGE_PATH"

stage_payload() {
  local target="$1"
  # /.git is the linked worktree's gitfile. Protect it from --delete so the
  # deployment worktree keeps its Git metadata.
  rsync -a --delete --exclude '/.git' "$SITE_DIR/" "$target/"
  : >"$target/.nojekyll"
}

if $dry_run; then
  rm -rf "$STAGE_PATH"
  mkdir -p "$STAGE_PATH"
  stage_payload "$STAGE_PATH"
  log "dry run: payload staged in $STAGE_PATH with .nojekyll; no branch or worktree was touched"
  echo
  echo "GATED COMMANDS - deliberately NOT run by --dry-run:"
  echo "  # first publication (branch does not exist yet):"
  echo "  git worktree add --orphan -b ${DEPLOY_BRANCH} '${DEPLOY_DIR}'"
  echo "  # later publications (branch already exists):"
  echo "  git worktree add '${DEPLOY_DIR}' ${DEPLOY_BRANCH}"
  echo "  # then re-run without --dry-run, review, stage, commit, and push separately:"
  echo "  git -C '${DEPLOY_DIR}' status --short -uall"
  echo "  git -C '${DEPLOY_DIR}' add -A"
  echo "  git -C '${DEPLOY_DIR}' commit -F '${BLOG_ROOT}/${MESSAGE_PATH}'"
  echo "  git push origin ${DEPLOY_BRANCH}"
  echo
  log "STOP: no deployment commit or push was made. Separate authorization is required."
  exit 0
fi

registered="$(git worktree list --porcelain | grep -c "^worktree ${DEPLOY_DIR}$" || true)"

if [[ "$registered" -eq 1 ]]; then
  log "reusing the registered ${DEPLOY_BRANCH} worktree at $DEPLOY_DIR"
elif git rev-parse --verify --quiet "refs/heads/${DEPLOY_BRANCH}" >/dev/null; then
  [[ -n "$(ls -A "$DEPLOY_DIR" 2>/dev/null)" ]] &&
    die "$DEPLOY_DIR is not empty and is not a registered ${DEPLOY_BRANCH} worktree; inspect and clear it manually"
  log "attaching a worktree to the existing ${DEPLOY_BRANCH} branch"
  git worktree add "$DEPLOY_DIR" "$DEPLOY_BRANCH"
elif git rev-parse --verify --quiet "refs/remotes/origin/${DEPLOY_BRANCH}" >/dev/null; then
  [[ -n "$(ls -A "$DEPLOY_DIR" 2>/dev/null)" ]] &&
    die "$DEPLOY_DIR is not empty and is not a registered ${DEPLOY_BRANCH} worktree; inspect and clear it manually"
  log "creating a local ${DEPLOY_BRANCH} branch tracking origin/${DEPLOY_BRANCH}"
  git worktree add --track -b "$DEPLOY_BRANCH" "$DEPLOY_DIR" "origin/${DEPLOY_BRANCH}"
else
  [[ -n "$(ls -A "$DEPLOY_DIR" 2>/dev/null)" ]] &&
    die "$DEPLOY_DIR is not empty and ${DEPLOY_BRANCH} does not exist; inspect and clear it manually"
  log "${DEPLOY_BRANCH} does not exist; creating an orphan deployment worktree"
  git worktree add --orphan -b "$DEPLOY_BRANCH" "$DEPLOY_DIR"
fi

stage_payload "$DEPLOY_DIR"

# Prove the payload is actually stageable. An inherited ignore rule or an empty
# staging area would otherwise produce an empty deployment commit silently.
pending="$(git -C "$DEPLOY_DIR" status --porcelain=v1 -uall)"
[[ -n "$pending" ]] ||
  die "the deployment worktree reports nothing to stage. Check its ignore configuration; refusing to continue with an empty payload."
if git -C "$DEPLOY_DIR" check-ignore --quiet index.html 2>/dev/null; then
  die "index.html is ignored inside the deployment worktree; the payload would not be committed"
fi

log "payload prepared in $DEPLOY_DIR for branch $DEPLOY_BRANCH"
echo
echo "SOURCE REVISION FOR THE DEPLOYMENT COMMIT:"
echo "  $source_sha"
echo
echo "PROPOSED DEPLOYMENT COMMIT MESSAGE ($MESSAGE_PATH):"
echo "-----"
cat "$MESSAGE_PATH"
echo "-----"
echo
echo "DEPLOYMENT WORKTREE STATUS (review before any commit):"
git -C "$DEPLOY_DIR" status --short -uall
echo
log "master is untouched: $(git -C "$BLOG_ROOT" status --porcelain=v1 -uall | wc -l) change(s) in the source working tree"
log "STOP: nothing was committed or pushed. Review the status above and obtain explicit"
log "authorization for the deployment commit and push (docs/deployment.md)."
