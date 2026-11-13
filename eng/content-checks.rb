#!/usr/bin/env ruby
#
# Authoritative editorial and source-metadata checks for the development blog.
#
# Usage: ruby eng/content-checks.rb
#
# Validates the approved hosting and identity configuration, repository hygiene rules,
# tab definitions, and every post/draft front matter. Stdlib-only plain Ruby, so it
# runs before and independently of the bundle restore.

require "date"
require "yaml"

ROOT = File.expand_path("..", __dir__)

POST_FILENAME = /\A(\d{4}-\d{2}-\d{2})-([a-z0-9](?:[a-z0-9-]*[a-z0-9])?)\.md\z/
TAG_PATTERN = /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/
SLUG_PATTERN = /[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/
DRAFT_MARKER = "EDITORIAL DRAFT"
UNAPPROVED_MARKERS = [DRAFT_MARKER, "NOT APPROVED FOR PUBLICATION", "PENDING EDITORIAL APPROVAL"].freeze
IDEMPOTENCY_KEY = /\A([\w.-]+\/[\w.-]+)#(\d+)\z/
SECRET_FILENAMES = /\A(\.env(\..*)?|.*\.(pem|key|p12|pfx|kerberos|credentials))\z/i

EXPECTED = {
  "url" => "https://heretical-solutions.github.io",
  "baseurl" => "/Heretical-Blog",
  "timezone" => "UTC",
  "title" => "Heretical Development",
  "lang" => "en",
  "theme" => "jekyll-theme-chirpy",
}.freeze

SOURCE_KEYS = %w[repository url pull_request merge_commit target_branch merged_at idempotency_key].freeze

@failures = []
@groups = 0

def check(label)
  @groups += 1
  before = @failures.size
  yield
  puts "  ok   #{label}" if @failures.size == before
end

def fail!(label, message)
  @failures << "#{label}: #{message}"
  puts "  FAIL #{label}: #{message}"
end

def rel(path)
  path.sub("#{ROOT}/", "")
end

def yaml_load(path)
  raw = File.read(path)
  return [nil, nil] unless raw.start_with?("---\n")

  match = raw.match(/\A---\n(.*?)\n(?:---|\.\.\.)\n?/m)
  return [nil, nil] unless match

  body = raw[(match[0].length)..].to_s
  begin
    [YAML.safe_load(match[1], permitted_classes: [Time, Date, DateTime, Symbol], aliases: true) || {}, body]
  rescue Psych::SyntaxError => e
    [{ "__parse_error" => e.message }, body]
  end
end

# Candidate files for hygiene scanning: everything Git would record, ignoring
# restored dependencies and generated output. Falls back to a pruned walk when the
# checkout has no Git metadata (for example a clean archive export).
def candidate_files
  if system("git", "-C", ROOT, "rev-parse", "--git-dir", out: File::NULL, err: File::NULL)
    paths = IO.popen(
      ["git", "-C", ROOT, "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
      &:read
    )
    return paths.split("\0").map { |path| File.join(ROOT, path) }.select { |path| File.file?(path) }
  end

  pruned = %w[vendor .bundle artifacts _site .jekyll-cache .git]
  Dir.glob(File.join(ROOT, "**", "*"), File::FNM_DOTMATCH).select do |path|
    File.file?(path) && !(path.split(File::SEPARATOR) & pruned).any?
  end
end

def config
  @config ||= YAML.safe_load(File.read(File.join(ROOT, "_config.yml")),
                             permitted_classes: [Time, Date, DateTime, Symbol], aliases: true)
end

def blank?(value)
  value.nil? || (value.respond_to?(:empty?) && value.empty?) || value == false
end

def nested(hash, *keys)
  keys.reduce(hash) { |acc, key| acc.is_a?(Hash) ? acc[key] : nil }
end

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

puts "content-checks: site configuration"

check "approved hosting identity" do
  EXPECTED.each do |key, expected|
    actual = config[key]
    fail!("config.#{key}", "expected #{expected.inspect}, got #{actual.inspect}") unless actual == expected
  end
end

check "comment systems, analytics, page views, and verification tokens are disabled" do
  fail!("config.comments.provider", "must be empty") unless blank?(nested(config, "comments", "provider"))
  %w[disqus utterances giscus].each do |provider|
    (config.dig("comments", provider) || {}).each do |key, value|
      fail!("config.comments.#{provider}.#{key}", "must be empty while comments are disabled") unless blank?(value)
    end
  end

  (config["analytics"] || {}).each do |provider, settings|
    (settings || {}).each do |key, value|
      fail!("config.analytics.#{provider}.#{key}", "must be empty") unless blank?(value)
    end
  end
  fail!("config.pageviews.provider", "must be empty") unless blank?(nested(config, "pageviews", "provider"))

  (config["webmaster_verifications"] || {}).each do |key, value|
    fail!("config.webmaster_verifications.#{key}", "must be empty") unless blank?(value)
  end
end

check "PWA and offline caching are disabled" do
  fail!("config.pwa.enabled", "must be false") unless config.dig("pwa", "enabled") == false
  fail!("config.pwa.cache.enabled", "must be false") unless config.dig("pwa", "cache", "enabled") == false
end

check "no invented social profiles, contact address, avatar, or CDN" do
  fail!("config.twitter", "must not be defined; no X/Twitter account is published") if config.key?("twitter")
  fail!("config.social.email", "must be empty") unless blank?(nested(config, "social", "email"))
  fail!("config.social.fediverse_handle", "must be empty") unless blank?(nested(config, "social", "fediverse_handle"))
  fail!("config.avatar", "must be empty; no stock art is published") unless blank?(config["avatar"])
  fail!("config.cdn", "must be empty; media is served from the project base path") unless blank?(config["cdn"])
  fail!("config.social_preview_image", "must be empty") unless blank?(config["social_preview_image"])
  fail!("config.github.username", "expected the organization login") unless nested(config, "github", "username") == "Heretical-Solutions"

  links = nested(config, "social", "links") || []
  unless links == ["https://github.com/Heretical-Solutions"]
    fail!("config.social.links", "expected the GitHub organization link only, got #{links.inspect}")
  end
end

check "third-party front-end libraries are not self-hosted" do
  fail!("config.assets.self_host.enabled", "must be falsy so no vendored JS/CSS is distributed") unless !config.dig("assets", "self_host", "enabled")
end

check "generated output and repository-only inputs are excluded from the payload" do
  exclude = config["exclude"] || []
  %w[docs eng vendor Gemfile Gemfile.lock README.md AGENTS.md THIRD_PARTY_NOTICES.md artifacts .ruby-version].each do |entry|
    fail!("config.exclude", "must list #{entry} so it is never published") unless exclude.include?(entry)
  end
  fail!("config.exclude", "must not exclude licenses/, whose texts are distributed with the payload") if exclude.include?("licenses")
end

check "post permalink stays stable" do
  defaults = config["defaults"] || []
  post = defaults.find { |d| d.dig("scope", "type") == "posts" && d.dig("scope", "path") == "" }
  fail!("config.defaults.posts", "must exist") if post.nil?
  fail!("config.defaults.posts.permalink", "expected /posts/:title/") unless post && post.dig("values", "permalink") == "/posts/:title/"
  fail!("config.defaults.posts.comments", "must be disabled") unless blank?(post && post.dig("values", "comments"))
end

# ---------------------------------------------------------------------------
# Repository hygiene
# ---------------------------------------------------------------------------

puts "content-checks: repository hygiene"

check "no custom domain, Actions workflow, submodule, or Node manifest" do
  {
    "CNAME" => "no custom domain is configured",
    ".gitmodules" => "Chirpy is consumed as a gem, never as a source submodule",
    "package.json" => "no npm toolchain is required by this packaged-gem site",
    "assets/lib" => "static assets are CDN-loaded, so no vendored library directory may exist",
  }.each do |path, reason|
    full = File.join(ROOT, path)
    fail!("hygiene.#{path}", "must not exist: #{reason}") if File.exist?(full)
  end

  workflows = File.join(ROOT, ".github", "workflows")
  fail!("hygiene..github/workflows", "must not exist in the initial manual-publication phase") if Dir.exist?(workflows)

  Dir.glob(File.join(ROOT, "**", "node_modules")).each do |path|
    fail!("hygiene.node_modules", "#{rel(path)} must not be committed")
  end
end

check "lock file is tracked and no secret material is present" do
  fail!("Gemfile.lock", "must be committed for deterministic restore") unless File.file?(File.join(ROOT, "Gemfile.lock"))

  candidate_files.each do |path|
    name = File.basename(path)
    next unless name.match?(SECRET_FILENAMES)

    fail!("hygiene.secret", "#{rel(path)} looks like credential material and must not be in the repository")
  end
end

check "no generated site output is tracked" do
  %w[_site .jekyll-cache artifacts vendor/bundle].each do |path|
    next unless File.exist?(File.join(ROOT, path))

    ignored = `git -C "#{ROOT}" check-ignore -v -- #{path} 2>/dev/null`.strip
    fail!("hygiene.#{path}", "exists but is not ignored by .gitignore") if ignored.empty?
  end
end

# ---------------------------------------------------------------------------
# Tabs
# ---------------------------------------------------------------------------

puts "content-checks: navigation tabs"

check "tab collection is complete and ordered" do
  tabs = Dir.glob(File.join(ROOT, "_tabs", "*.md")).sort
  names = tabs.map { |path| File.basename(path, ".md") }
  %w[about archives categories tags].each do |required|
    fail!("tabs", "missing required tab #{required}.md") unless names.include?(required)
  end

  orders = []
  tabs.each do |path|
    data, body, = yaml_load(path)
    label = rel(path)
    fail!(label, "front matter is required") if data.nil?
    next if data.nil?

    fail!(label, "icon is required") if blank?(data["icon"])
    order = data["order"]
    fail!(label, "order is required and must be an Integer") unless order.is_a?(Integer)
    orders << order

    if File.basename(path, ".md") == "about"
      fail!(label, "must carry real About content, not starter placeholder text") if blank?(body.to_s.strip) || body.to_s.include?("Add Markdown syntax content")
    end
  end
  fail!("tabs.order", "orders must be unique, got #{orders.inspect}") unless orders.uniq.size == orders.size
end

# ---------------------------------------------------------------------------
# Posts and drafts
# ---------------------------------------------------------------------------

puts "content-checks: content"

def validate_entry(path, kind)
  label = rel(path)
  filename = File.basename(path)
  match = POST_FILENAME.match(filename)
  fail!(label, "filename must be YYYY-MM-DD-<slug>.md with a lowercase slug") if match.nil?
  date_part, slug = match ? [match[1], match[2]] : [nil, nil]

  data, body, = yaml_load(path)
  if data&.key?("parse_error") || data&.key?("__parse_error")
    fail!(label, "front matter is not valid YAML: #{data['__parse_error']}")
    return
  end
  fail!(label, "front matter block is required") if data.nil?
  return if data.nil?

  title = data["title"]
  fail!(label, "title is required and must be a non-empty String") unless title.is_a?(String) && !title.strip.empty?

  date = data["date"]
  unless date.is_a?(Time)
    fail!(label, "date must include an explicit UTC offset, e.g. 2026-01-15 09:00:00 +0000")
    return
  end
  fail!(label, "date offset must be +0000; the site records time in UTC") unless date.utc_offset.zero?
  fail!(label, "date #{date.to_date} disagrees with filename date #{date_part}") if date_part && date.to_date.to_s != date_part
  fail!(label, "date is in the future") if date.to_i > Time.now.to_i + 60

  categories = data["categories"]
  unless categories.is_a?(Array) && !categories.empty? && categories.all? { |c| c.is_a?(String) && !c.strip.empty? && c == c.strip }
    fail!(label, "categories must be a non-empty array of one or two unpadded Strings")
  end
  fail!(label, "categories supports at most a primary and secondary level") if categories.is_a?(Array) && categories.size > 2

  tags = data["tags"]
  unless tags.is_a?(Array) && !tags.empty? && tags.all? { |t| t.is_a?(String) && t.match?(TAG_PATTERN) }
    fail!(label, "tags must be a non-empty array of lowercase slug-like Strings")
  end

  fail!(label, "permalink must come from site defaults, not front matter") if data.key?("permalink")
  fail!(label, "layout must come from site defaults, not front matter") if data.key?("layout")
  fail!(label, "comments must stay disabled") unless blank?(data["comments"])

  body = body.to_s
  if kind == :draft
    fail!(label, "a draft must carry the #{DRAFT_MARKER} marker for editorial review") unless body.include?(DRAFT_MARKER)
  else
    UNAPPROVED_MARKERS.each do |marker|
      fail!(label, "a published post must not carry the unapproved marker #{marker.inspect}") if body.include?(marker)
    end
  end

  validate_source(label, data, kind)
  validate_media(label, data, body)

  yield(slug) if block_given?
end

def validate_source(label, data, kind)
  source = data["source"]
  return if source.nil?

  unless source.is_a?(Hash)
    fail!(label, "source must be a mapping of generated-note metadata")
    return
  end

  missing = SOURCE_KEYS - source.keys
  fail!(label, "generated note is missing source metadata: #{missing.join(', ')}") unless missing.empty?

  repository = source["repository"].to_s
  fail!(label, "source.repository must be owner/repo") unless repository.match?(%r{\A[\w.-]+/[\w.-]+\z})

  key = source["idempotency_key"].to_s
  unless key.match?(IDEMPOTENCY_KEY)
    fail!(label, "source.idempotency_key must be <source-repository>#<pull-request-number>")
  else
    derived = IDEMPOTENCY_KEY.match(key)
    fail!(label, "source.idempotency_key repository #{derived[1]} disagrees with source.repository #{repository}") unless derived[1] == repository
    fail!(label, "source.idempotency_key PR number #{derived[2]} disagrees with source.pull_request #{source['pull_request']}") unless derived[2] == source["pull_request"].to_s
  end

  url = source["url"].to_s
  fail!(label, "source.url must be an https URL for the canonical event") unless url.start_with?("https://")
  fail!(label, "source.url must point at source.repository") unless url.include?("://github.com/#{repository}/") || url.include?("://#{repository}")

  merge_commit = source["merge_commit"].to_s
  fail!(label, "source.merge_commit must be a full 40-character SHA") unless merge_commit.match?(/\A\h{40}\z/)

  fail!(label, "source.merged_at must be an explicit timestamp") unless source["merged_at"].is_a?(Time) || source["merged_at"].to_s.match?(/\A\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:Z|[+-]\d{4})\z/)

  if kind == :post
    approval = data["editorial_approval"]
    unless approval.is_a?(Hash) && !blank?(approval["reviewer"]) && !blank?(approval["approved_at"])
      fail!(label, "a generated note in _posts must record editorial_approval with reviewer and approved_at")
    end
  end
end

def validate_media(label, data, body)
  refs = []
  image = data["image"]
  refs << image if image.is_a?(String)

  body.to_s.scan(%r{!\[[^\]]*\]\(([^)\s]+)[^)]*\)}) { refs << Regexp.last_match(1) }
  body.to_s.scan(%r{(?:src|href)="(/assets/posts/[^"]+)"}) { refs << Regexp.last_match(1) }

  refs.each do |ref|
    next unless ref.start_with?("/assets/")

    path = File.join(ROOT, ref)
    fail!(label, "references missing media #{ref}") unless File.exist?(path)
  end

  body.to_s.scan(/(!)\[([^\]]*)\]\([^)]*\)/) do |bang, alt|
    fail!(label, "images need non-empty alt text; found ![](...)") if bang && alt.strip.empty?
  end
end

slugs = {}

Dir.glob(File.join(ROOT, "_posts", "*.md")).sort.each do |path|
  validate_entry(path, :post) { |slug| (slugs[slug] ||= []) << "post" }
end

Dir.glob(File.join(ROOT, "_drafts", "*.md")).sort.each do |path|
  validate_entry(path, :draft) { |slug| (slugs[slug] ||= []) << "draft" }
end

check "post and draft slugs are unique" do
  slugs.each { |slug, kinds| fail!("slug.#{slug}", "used by #{kinds.join(', ')}; permalinks would collide") if kinds.size > 1 }
end

check "the published collection is not empty" do
  fail!("content", "_posts must contain at least one approved post for a production deployment") if Dir.glob(File.join(ROOT, "_posts", "*.md")).empty?
end

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------

puts "content-checks: #{@groups} groups, #{@failures.size} failure(s)"
unless @failures.empty?
  puts "content-checks: failures"
  @failures.each { |f| puts "  - #{f}" }
end
exit(@failures.empty? ? 0 : 1)
