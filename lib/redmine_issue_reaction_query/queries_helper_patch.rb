# frozen_string_literal: true

module RedmineIssueReactionQuery
  # Shows Redmine's bundled "thumb-up-filled" icon instead of the caption in
  # the header of the reactions column (plugin setting "Reactions column
  # header"). Only that column is affected; everything else goes to super.
  module QueriesHelperPatch
    def column_header(query, column, options = {})
      return super unless reaction_query_icon_header?(column)

      # The core uses column.caption for the sort link title too, so pass the
      # plain-text title explicitly (sort_link_options overrides it).
      title = l(:label_sort_by, "\"#{column.caption}\"")
      sort_link_options = { title: title }.merge(options[:sort_link_options] || {})

      super(query, reaction_query_icon_column(column),
            options.merge(sort_link_options: sort_link_options))
    end

    private

    def reaction_query_icon_header?(column)
      column.is_a?(RedmineIssueReactionQuery::IssueQueryPatch::ReactionsCountColumn) &&
        RedmineIssueReactionQuery.header_icon?
    end

    # A copy of the column whose caption is the icon. The caption text is kept
    # for screen readers (.hidden-for-sighted is defined by Redmine core).
    def reaction_query_icon_column(column)
      icon = safe_join(
        [sprite_icon('thumb-up'),
         content_tag(:span, column.caption, class: 'hidden-for-sighted')]
      )
      column.dup.tap do |copy|
        copy.define_singleton_method(:caption) { icon }
      end
    end
  end
end
