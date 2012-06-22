require 'redmine'

Dispatcher.to_prepare do
    Issue.send(:include, IssueSolr)
end


Redmine::Plugin.register :redmine_sunspot do
  name 'Redmine Index Attachments plugin'
  author 'Jochen Hansmeyer'
  description 'This implements fulltext search in issue attachments'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end
