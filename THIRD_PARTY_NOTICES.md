# Third-Party Notices

Dependency inventory for the Heretical Development blog. It supplements, and does not
replace, the superproject's aggregate notices.

Exact resolved versions come from the committed `Gemfile.lock`, which also carries a
SHA-256 checksum per gem. Regenerate this inventory's version columns from that lock file
rather than editing numbers by hand.

## Distribution model

This repository ships source only on `master`. The published artifact is a **prebuilt
static site** on the deployment-only `gh-pages` branch, produced by `eng/build.sh`.

The static payload conveys:

- Generated HTML, the theme's compiled CSS and JavaScript bundles, the theme's
  `assets/js/data/*` endpoints and `site.webmanifest`, the product-owned favicon set (which
  replaces the theme's upstream artwork),   `assets/feed.xml`, `assets/robots.txt`,
  `404.html`, this product's `LICENSE`, and the upstream texts under `/licenses/`.
  Post-specific screenshots are distributed only when their approved post is promoted;
  unapproved drafts and their content remain outside the production payload.
- Nothing else. No Ruby gem, no native library, no build script, and no repository
  documentation is placed in the payload.

Third-party front-end libraries listed under *External runtime references* are fetched by
the visitor's browser from a public CDN. This product does not copy, link, statically or
dynamically link, or otherwise convey them.

## Components distributed in the static payload

| Component | Version | License | SPDX | Source | Files conveyed | Notice location |
|---|---|---|---|---|---|---|
| Chirpy Jekyll theme | 7.6.0 | MIT | `MIT` | <https://github.com/cotes2020/jekyll-theme-chirpy> | Compiled CSS (`assets/css/jekyll-theme-chirpy.css` and source map), JavaScript bundles (`/*.min.js`, `assets/js/dist/*.min.js`, `assets/js/data/*`), generated markup derived from theme layouts, `assets/feed.xml`, `assets/robots.txt`, `404.html` | Per-file banner in the JS bundles and `licenses/jekyll-theme-chirpy-LICENSE.txt`, published at `/licenses/jekyll-theme-chirpy-LICENSE.txt` |
| Chirpy Starter | 7.6-compatible starter snapshot | MIT | `MIT` | <https://github.com/cotes2020/chirpy-starter> | Locally owned configuration, navigation, plugins, and starter-derived site input used to generate markup | `licenses/chirpy-starter-LICENSE.txt`, published at `/licenses/chirpy-starter-LICENSE.txt` |
| Bootstrap | 5.3.8 | MIT | `MIT` | <https://github.com/twbs/bootstrap> | Compiled into the theme's CSS bundle (grid/utility/component rules) and into the theme's JavaScript bundles | Preserved upstream banner at the head of the compiled CSS and in the bundles, plus `licenses/bootstrap-LICENSE.txt`, published at `/licenses/bootstrap-LICENSE.txt` |

Bootstrap is not a separate package dependency of this repository. Chirpy 7.6.0 compiles it
into its own stylesheet and bundles, so its MIT notice travels with our distributed output
and is retained in both the file headers and the published `licenses/` directory.

These components do not require corresponding source for the conveyed output under
MIT. Source availability is nevertheless satisfied in practice: the published footer links
to the upstream theme, and this repository's `master` branch holds the exact pinned
Gemfile/lock that reproduces the payload.

### Local modifications to upstream-owned inputs

| File | Upstream origin | Modification | Rationale |
|---|---|---|---|
| `_data/locales/en.yml` | Chirpy 7.6.0 `_data/locales/en.yml` | Copy with only the `copyright` block changed to MIT attribution for Heretical Solutions | The theme default asserts CC BY 4.0 for posts, which is not this product's licensing |
| `assets/img/favicons/*` | Chirpy 7.6.0 favicons (upstream art sourced from ClipartMAX) | Replaced the entire set with a product-owned geometric "H" mark, regenerated from `favicon.svg` | No stock or third-party illustration is published as this product's identity; the replacements are our own authorship |
| `_plugins/posts-lastmod-hook.rb` | Chirpy starter `_plugins/posts-lastmod-hook.rb` | Skip the Git query when the checkout has no history, and silence `git` stderr | A clean archive export or a pre-first-commit clone has no `HEAD`; the upstream form printed a fatal Git message into every build log |
| `_config.yml` | Chirpy starter `_config.yml` | Site identity, project Pages `url`/`baseurl`, UTC timezone, feature switches, and an extended `exclude` list | Product configuration, not a theme patch |
| `_data/contact.yml`, `_data/share.yml` | Chirpy starter | Reduced to the GitHub organization link and the site's own feed; sharing platforms removed | No invented social profiles, and no third-party share links for an internal record |
| `Gemfile` | Chirpy starter | Unchanged dependency set | Chirpy stays a packaged gem |
| `Gemfile.lock` | Generated here | Committed, unlike the upstream starter which ignores it | Required for deterministic restore by workspace dependency policy |

Theme files are otherwise consumed unmodified from the gem. The theme is never forked,
vendored, or patched in place.

## Build-only runtime dependencies (not conveyed)

These gems run site generation on the build host. Their code is not distributed in the
payload; only their generated output is, as described above.

| Gem | Version | License (declared) | Source |
|---|---|---|---|
| addressable | 2.9.2 | Apache-2.0 | <https://github.com/sporkmonger/addressable> |
| base64 | 0.3.0 | Ruby, BSD-2-Clause | <https://github.com/ruby/base64> |
| bigdecimal | 3.3.1 | Ruby, BSD-2-Clause | <https://github.com/ruby/bigdecimal> |
| colorator | 1.1.0 | MIT | <https://github.com/octopress/colorator> |
| concurrent-ruby | 1.3.8 | MIT | <https://github.com/ruby-concurrency/concurrent-ruby> |
| csv | 3.3.7 | Ruby, BSD-2-Clause | <https://github.com/ruby/csv> |
| em-websocket | 0.5.3 | MIT | <https://github.com/igrigorik/em-websocket> |
| eventmachine | 1.2.7 | Ruby, GPL-2.0 (dual; Ruby option used) | <https://rubyeventmachine.com> |
| ffi | 1.17.4 | BSD-3-Clause | <https://github.com/ffi/ffi/> |
| forwardable-extended | 2.6.0 | MIT | <https://github.com/envygeeks/forwardable-extended> |
| google-protobuf | 4.36.2 | BSD-3-Clause | <https://github.com/protocolbuffers/protobuf> |
| http_parser.rb | 0.8.1 | MIT | <https://github.com/tmm1/http_parser.rb> |
| i18n | 1.15.2 | MIT | <https://github.com/ruby-i18n/i18n> |
| jekyll | 4.4.1 | MIT | <https://github.com/jekyll/jekyll> |
| jekyll-archives | 2.3.0 | MIT | <https://github.com/jekyll/jekyll-archives> |
| jekyll-include-cache | 0.3.2 | MIT | <https://github.com/benbalter/jekyll-include-cache> |
| jekyll-paginate | 1.1.0 | MIT | <https://github.com/jekyll/jekyll-paginate> |
| jekyll-sass-converter | 3.1.0 | MIT | <https://github.com/jekyll/jekyll-sass-converter> |
| jekyll-seo-tag | 2.9.1 | MIT | <https://github.com/jekyll/jekyll-seo-tag> |
| jekyll-sitemap | 1.4.0 | MIT | <https://github.com/jekyll/jekyll-sitemap> |
| jekyll-theme-chirpy | 7.6.0 | MIT | See *Components distributed* above |
| jekyll-watch | 2.2.1 | MIT | <https://github.com/jekyll/jekyll-watch> |
| json | 2.21.2 | Ruby | <https://github.com/ruby/json> |
| kramdown | 2.5.2 | MIT | <https://kramdown.gettalong.org> |
| kramdown-parser-gfm | 1.1.0 | MIT | <https://github.com/kramdown/parser-gfm> |
| liquid | 4.0.4 | MIT | <https://github.com/Shopify/liquid> |
| listen | 3.10.1 | MIT | <https://github.com/guard/listen> |
| logger | 1.7.0 | Ruby, BSD-2-Clause | <https://github.com/ruby/logger> |
| mercenary | 0.4.0 | MIT | <https://github.com/jekyll/mercenary> |
| pathutil | 0.16.2 | MIT | <https://github.com/envygeeks/pathutil> |
| public_suffix | 7.0.5 | MIT | <https://github.com/weppos/publicsuffix-ruby> |
| rake | 13.4.2 | MIT | <https://github.com/ruby/rake> |
| rb-fsevent | 0.11.2 | MIT | <https://github.com/thibaudgg/rb-fsevent> |
| rb-inotify | 0.11.1 | MIT | <https://github.com/guard/rb-inotify> |
| rexml | 3.4.4 | BSD-2-Clause | <https://github.com/ruby/rexml> |
| rouge | 4.7.0 | MIT, BSD-2-Clause | <https://github.com/rouge-ruby/rouge> |
| safe_yaml | 1.0.5 | MIT | <https://github.com/dtao/safe_yaml> |
| sass-embedded | 1.108.2 | MIT | <https://github.com/sass-contrib/sass-embedded-host-ruby> |
| terminal-table | 3.0.2 | MIT | <https://github.com/tj/terminal-table> |
| unicode-display_width | 2.6.0 | MIT | <https://github.com/janlelis/unicode-display_width> |
| webrick | 1.9.2 | Ruby, BSD-2-Clause | <https://github.com/ruby/webrick> |

`sass-embedded` pulls the Dart Sass compiler binary and `google-protobuf` its native
runtime. Both stay in the ignored `vendor/bundle` directory and are never published.
Rouge contributes only CSS class names and inline markup through Kramdown; no Rouge source
or theme file is copied into the payload.

## Validation-only dependencies (not conveyed)

Reached only through `html-proofer` in the `:test` Bundler group.

| Gem | Version | License (declared) | Source |
|---|---|---|---|
| Ascii85 | 2.0.1 | MIT | <https://github.com/DataWraith/ascii85gem> |
| afm | 1.0.1 | MIT | <https://github.com/halfbyte/afm> |
| async | 2.37.0 | MIT | <https://github.com/socketry/async> |
| benchmark | 0.5.0 | Ruby, BSD-2-Clause | <https://github.com/ruby/benchmark> |
| console | 1.34.3 | MIT | <https://github.com/socketry/console> |
| ethon | 0.19.2 | MIT | <https://github.com/typhoeus/ethon> |
| fiber-annotation | 0.2.0 | MIT | <https://github.com/ioquatix/fiber-annotation> |
| fiber-local | 1.1.0 | MIT | <https://github.com/socketry/fiber-local> |
| fiber-storage | 1.0.1 | MIT | <https://github.com/ioquatix/fiber-storage> |
| hashery | 2.1.2 | BSD-2-Clause | <https://github.com/rubyworks/hashery> |
| html-proofer | 5.2.3 | MIT | <https://github.com/gjtorikian/html-proofer> |
| io-event | 1.11.2 | MIT | <https://github.com/socketry/io-event> |
| metrics | 0.15.0 | MIT | <https://github.com/socketry/metrics> |
| nokogiri | 1.19.7 | MIT | <https://github.com/sparklemotion/nokogiri> |
| pdf-reader | 2.16.0 | MIT | <https://github.com/yob/pdf-reader> |
| racc | 1.8.1 | Ruby, BSD-2-Clause | <https://github.com/ruby/racc> |
| rainbow | 3.1.1 | MIT | <https://github.com/sickill/rainbow> |
| traces | 0.18.2 | MIT | <https://github.com/socketry/traces> |
| ttfunk | 1.8.0 | Nonstandard, GPL-2.0-only, GPL-3.0-only | <https://github.com/prawnpdf/ttfunk> |
| typhoeus | 1.7.1 | MIT | <https://github.com/typhoeus/typhoeus> |
| yell | 2.2.2 | MIT | <https://github.com/rudionrails/yell> |
| zeitwerk | 2.8.3 | MIT | <https://github.com/fxn/zeitwerk> |

`addressable`, `bigdecimal`, `ffi`, `json`, `logger`, and `public_suffix` are shared with
the runtime closure and are listed once, in the table above.

`ttfunk` declares a non-standard plus GPL-2.0-only/GPL-3.0-only combination. It is reached
only by `pdf-reader` for HTML Proofer's optional PDF checks, runs on the build host, and is
never distributed, so no copyleft obligation attaches to the published site. **Review
trigger:** if any future change distributes `pdf-reader`/`ttfunk` code or output, or moves
them into the runtime group, re-assess this before publication.

## External runtime references

The visitor's browser fetches these from public CDNs. Nothing is copied into this
repository or into the static payload, so no source-availability or attribution obligation
attaches to this product. Licenses are recorded for awareness from the pinned upstream
major versions.

| Library | Version range | Declared license | Reference |
|---|---|---|---|
| Font Awesome Free | 7 | MIT (code), CC BY 4.0 (icons), SIL OFL 1.1 (fonts) | <https://github.com/FortAwesome/Font-Awesome> |
| Simple Jekyll Search | 1 | MIT | <https://github.com/christian-fei/Simple-Jekyll-Search> |
| tocbot | 4 | MIT | <https://github.com/tscanlin/tocbot> |
| Mermaid | 11 | MIT | <https://github.com/mermaid-js/mermaid> |
| day.js | 1 | MIT | <https://github.com/iamkun/dayjs> |
| GLightbox | 3 | MIT | <https://github.com/biati-digital/glightbox> |
| loading-attribute-polyfill | 2 | MIT | <https://github.com/GoogleChromeLabs/loading-attribute-polyfill> |
| Clipboard.js | 2 | MIT | <https://github.com/zenorocha/clipboard.js> |
| MathJax | 4 | Apache-2.0 | <https://github.com/mathjax/MathJax> |
| Lato | as served | SIL OFL 1.1 | <https://fonts.google.com/specimen/Lato> |
| Source Sans Pro | as served | SIL OFL 1.1 | <https://fonts.google.com/specimen/Source+Sans+Pro> |

**Review trigger:** enabling `assets.self_host` in `_config.yml`, or adding an
`assets/lib` vendoring step, would start distributing these components and would require
their license texts and notices in the payload. That change has not been made and would
need this document updated in the same commit.

## Assets and content

- The favicon set under `assets/img/favicons/` is product-owned authorship (MIT, this
  repository's license). No stock or generated illustration is published.
- Authored posts are MIT, matching the repository code. The theme's default post-license
  footer text is overridden to state this.
- No photography or video is currently published. Any future media must record origin,
  author, license, and modifications in `docs/editorial.md`'s provenance rules before it is
  committed.
- The approved ntfy LAN deployment post includes a user-supplied Android screenshot under
  `assets/posts/2026-11-14-ntfy-lan-deployment/`, converted without content edits from PNG
  to WebP. Its `captions.md` records origin, disclosure, licensing, modifications and alt
  text. The factual capture depicts the upstream ntfy Android application
  (<https://github.com/binwiederhier/ntfy-android>); no application executable, source,
  library or separate artwork file is distributed. Editorial approval is recorded in the
  post's front matter; website deployment remains a separately authorized operation.
- The approved Doxygen portal post includes two factual Firefox screenshots under
  `assets/posts/2026-11-14-doxygen-documentation-portal/`, converted without content edits
  from PNG to WebP. Their `captions.md` records origin, capture revisions, licensing,
  modifications, and alt text. The screenshots are blog-owned captures of Heretical-owned
  content under MIT. Their rendered third-party components are Doxygen Awesome CSS 2.5.0
  and Doxygen-generated JavaScript (MIT) and Material Icons glyphs (Apache-2.0), sourced
  from portal revision `e02da8b27803a4c172a6928bf13976241bdf9c8e`; Doxygen itself is a
  build-only generator and is not distributed in the images. Visible Doxygen attribution is
  preserved, and the portal distributes its applicable license texts under
  `https://heretical-solutions.github.io/Heretical-Documentation/licenses/`. The post has
  received editorial approval; website deployment remains a separately authorized operation.

## Obligations summary

| Obligation | Status |
|---|---|
| Retain MIT copyright and permission notices for distributed code | Met: file banners preserved, texts published under `/licenses/` |
| Provide corresponding source for distributed compiled output | Not required by MIT; source remains available at the pinned `master` revision |
| Share-alike or copyleft compliance | Not triggered: no GPL/LGPL/AGPL component is distributed; `eventmachine` and `ttfunk` are build/validation-only |
| Trademark or attribution display for Font Awesome/Google Fonts | Not applicable: not conveyed; fetched by the visitor from CDNs |
| Patent-specific terms | No additional patent-specific requirements identified for the distributed MIT components; review when dependencies change |
| SBOM for releases | Not required in the initial manual-publication phase; `Gemfile.lock` checksums provide the machine-readable integrity input |

Uncertain or conditional items are flagged above as review triggers rather than resolved as
compliant.
