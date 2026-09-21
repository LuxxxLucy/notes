# Sets page.created and page.updated from git history for pages under content/.
# A file with no commit gets neither field.
require "shellwords"

Jekyll::Hooks.register :pages, :post_init do |page|
  next unless page.path.start_with?("content/")

  git = "git -C #{Shellwords.escape(page.site.source)} log --follow --format=%as"
  file = Shellwords.escape(page.path)
  created = `#{git} --diff-filter=A -- #{file}`.lines.last.to_s.strip
  updated = `#{git} -1 -- #{file}`.strip
  next if created.empty?

  page.data["created"] = created
  page.data["updated"] = updated
end
