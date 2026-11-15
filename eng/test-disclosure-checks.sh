#!/usr/bin/env bash
# Exercise public/private editorial disclosure guards against synthetic fixtures.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/heretical-blog-disclosure-test.XXXXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT INT TERM
mkdir -p "$TMP/_posts" "$TMP/_drafts"

fail_expected() {
  local label="$1" file="$2"
  if ruby "$ROOT/eng/content-checks.rb" "$TMP" --disclosure-fixture-only >"$TMP/out" 2>&1; then
    printf 'FAIL: accepted %s\n' "$label" >&2
    exit 1
  fi
  if ! grep -q 'not permitted\|developer-specific' "$TMP/out"; then
    printf 'FAIL: %s did not identify a disclosure violation\n' "$label" >&2
    exit 1
  fi
  rm -f -- "$file"
}

# content-checks accepts a fixture root only for this test; normal invocation
# remains rooted at the blog repository and performs all existing checks.
cat >"$TMP/_posts/2026-11-15-safe.md" <<'EOF'
---
title: Safe editorial example
date: 2026-11-15 12:00:00 +0000
categories: [Workspace]
tags: [testing]
source:
  repository: Heretical Development workspace
  publication: https://heretical-solutions.github.io/Heretical-Documentation/
  idempotency_key: safe-editorial-example
editorial_approval:
  reviewer: reviewer
  approved_at: 2026-11-15 12:00:00 +0000
---
A reviewed workspace change.
EOF

# The checker must fail closed for a malformed fixture too; the self-test only
# uses it in fixture mode where the normal repository checks are not applicable.
for case_name in private-link private-pr private-metadata machine-path; do
  cp "$TMP/_posts/2026-11-15-safe.md" "$TMP/_drafts/2026-11-15-$case_name.md"
  case "$case_name" in
    private-link) printf '\n[source](https://github.com/Heretical-Solutions/Heretical-Development/pull/99)\n' >>"$TMP/_drafts/2026-11-15-$case_name.md" ;;
        private-pr) printf '\nSuperproject PR #99 is private.\n' >>"$TMP/_drafts/2026-11-15-$case_name.md" ;;
    private-metadata) sed -i '/^  idempotency_key:/i\  merge_commit: 0123456789012345678901234567890123456789' "$TMP/_drafts/2026-11-15-$case_name.md" ;;
    machine-path) printf '\nLocal path: /home/developer/Development\n' >>"$TMP/_drafts/2026-11-15-$case_name.md" ;;
  esac
  fail_expected "$case_name" "$TMP/_drafts/2026-11-15-$case_name.md"
done
if ! ruby "$ROOT/eng/content-checks.rb" "$TMP" --disclosure-fixture-only >"$TMP/out" 2>&1; then
  cat "$TMP/out" >&2
  printf 'FAIL: safe public metadata was rejected\n' >&2
  exit 1
fi
printf 'disclosure fixture cases rejected: 4; safe public metadata accepted\n'
