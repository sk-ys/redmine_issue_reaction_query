# frozen_string_literal: true

Redmine::Plugin.register :redmine_issue_reaction_query do
  name 'Redmine Issue Reaction Query'
  author 'sk-ys'
  description 'Adds a sortable "Reactions" column and filters (count / reacted by me) for issue reactions to the issue list'
  version '0.3.0'
  url 'https://github.com/sk-ys/redmine_issue_reaction_query'
  author_url 'https://github.com/sk-ys'
  requires_redmine version_or_higher: '6.1.0'

  settings default: { 'header_display' => 'icon' },
           partial: 'settings/redmine_issue_reaction_query'

  project_module :issue_tracking do
    permission :use_reaction_query, {}, read: true
  end
end

# unless IssueQuery.include?(RedmineIssueReactionQuery::IssueQueryPatch)
#   IssueQuery.prepend RedmineIssueReactionQuery::IssueQueryPatch
# end

# The IssueQuery / QueriesHelper patches are applied from the after_plugins_loaded hook
# (see lib/redmine_issue_reaction_query/hooks/model_hook.rb), not here.
# Referencing the class loads it and registers the hook listener.
RedmineIssueReactionQuery::Hooks::ModelHook
