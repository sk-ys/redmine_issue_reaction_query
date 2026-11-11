# frozen_string_literal: true

module RedmineIssueReactionQuery
  module Hooks
    # Applies the IssueQuery patch AFTER all plugins have been loaded.
    #
    # Some plugins patch IssueQuery with alias_method chains from their own
    # after_plugins_loaded hook. If this plugin prepended its module earlier
    # (in init.rb), such an alias would capture our prepended method and end
    # in infinite recursion. Listeners are called in registration order
    # (plugins load alphabetically), so ours runs after theirs.
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        return if IssueQuery.include?(RedmineIssueReactionQuery::IssueQueryPatch)

        IssueQuery.prepend RedmineIssueReactionQuery::IssueQueryPatch
      end
    end
  end
end
