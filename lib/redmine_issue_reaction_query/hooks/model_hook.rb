# frozen_string_literal: true

module RedmineIssueReactionQuery
  module Hooks
    # Applies the IssueQuery and QueriesHelper patches AFTER all plugins have
    # been loaded.
    #
    # Some plugins patch these classes with alias_method chains from their own
    # after_plugins_loaded hook. If this plugin prepended its modules earlier
    # (in init.rb), such an alias would capture our prepended method and end
    # in infinite recursion. Listeners are called in registration order
    # (plugins load alphabetically), so ours runs after theirs.
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        unless IssueQuery.include?(RedmineIssueReactionQuery::IssueQueryPatch)
          IssueQuery.prepend RedmineIssueReactionQuery::IssueQueryPatch
        end

        return if QueriesHelper.include?(RedmineIssueReactionQuery::QueriesHelperPatch)

        QueriesHelper.prepend RedmineIssueReactionQuery::QueriesHelperPatch
      end
    end
  end
end
