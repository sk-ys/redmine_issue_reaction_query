# frozen_string_literal: true

module RedmineIssueReactionQuery
  # Plugin setting "Reactions column header": 'icon' (default) or 'text'.
  # Also true when the setting has never been saved.
  def self.header_icon?
    settings = Setting.plugin_redmine_issue_reaction_query
    value = settings['header_display'] if settings.is_a?(Hash)
    (value.presence || 'icon') == 'icon'
  end
end
