#!/usr/bin/env ruby
#
# Check for changed posts
#
# Local modification of the Chirpy starter hook: derive `last_modified_at` from Git
# history only when this checkout actually has history to query. A clean archive
# export, or a fresh clone before the first commit, has no `HEAD`, and the upstream
# form of this hook lets the failing `git` invocation print to the build log.

Jekyll::Hooks.register :posts, :post_init do |post|
  next unless system("git", "rev-parse", "--verify", "--quiet", "HEAD", out: File::NULL, err: File::NULL)

  commit_num = `git rev-list --count HEAD "#{ post.path }" 2>/dev/null`

  if commit_num.to_i > 1
    lastmod_date = `git log -1 --pretty="%ad" --date=iso "#{ post.path }" 2>/dev/null`
    post.data['last_modified_at'] = lastmod_date unless lastmod_date.strip.empty?
  end

end
