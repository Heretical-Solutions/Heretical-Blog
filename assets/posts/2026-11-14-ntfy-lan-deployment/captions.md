# Media provenance — LAN-only ntfy deployment

Post: `2026-11-14-ntfy-lan-deployment`

## `android-notifications.webp`

- Origin: user-supplied factual Android screenshot, captured on 2026-11-14 from the working
  ntfy LAN deployment. Original input: `Screenshot_20261114-210523.png` in the operator's
  local sharing folder; the machine-local path is intentionally not published.
- Capture dimensions: original 720 × 1600 pixels; published crop 720 × 1300 pixels.
- Modification: cropped at `(0, 300)` to remove the application/server address bar and
  status clock, then converted from PNG to WebP at quality 88. No retouching, text edits,
  redaction within the retained area, or interface alterations.
- Visible content: timestamped `Android test` messages and the application's message
  composer/navigation controls. The published crop contains no server address, credentials,
  access tokens, account names, personal information, customer data, or secret payloads.
  The user supplied the image for this development note and approved the cleanup.
- Alt text: Android ntfy application displaying several timestamped Android test messages
  from the LAN deployment.
- Caption: the ntfy Android application displays test notifications delivered by the
  trusted-LAN deployment. It does not demonstrate background delivery, off-LAN access,
  or service availability during an outage.

## Authorship and licensing

- Screenshot supplied by Heretical Solutions for publication under this repository's MIT
  license, consistent with its authored content.
- The screenshot depicts the upstream ntfy Android application. No ntfy application source,
  executable, artwork file, or library is distributed separately by this blog post; the
  factual interface capture is included as development evidence.
- ntfy upstream: <https://github.com/binwiederhier/ntfy>. Its server is dual-licensed under
  Apache-2.0 or GPLv2; this screenshot does not select a server license or modify upstream
  code. Android application license information:
  <https://github.com/binwiederhier/ntfy-android>.
- Standard Android status/navigation glyphs remain unchanged as part of the user-supplied
  device capture. No third-party icon file is extracted or redistributed as a separate asset.
