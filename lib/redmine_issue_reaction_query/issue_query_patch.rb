# frozen_string_literal: true

Query # autoload query.rb, which defines QueryColumn

module RedmineIssueReactionQuery
  # Reactions on the issue itself only (journals/notes are NOT counted).
  module IssueQueryPatch
    # Reaction count of the issue (all users, no visibility filtering)
    def self.count_sql
      "(SELECT COUNT(*) FROM #{::Reaction.table_name} rq " \
        "WHERE rq.reactable_type = 'Issue' " \
        "AND rq.reactable_id = #{::Issue.table_name}.id)"
    end

    class ReactionsCountColumn < ::QueryColumn
      def initialize
        super(
          :reactions_count,
          sortable: -> { IssueQueryPatch.count_sql },
          default_order: 'desc',
          caption: :label_reactions_count
        )
      end

      # Value is preloaded in IssueQuery#issues (see below)
      def value_object(issue)
        issue.instance_variable_get(:@reactions_count_value) || 0
      end

      def value(issue)
        value_object(issue)
      end
    end

    # ---- columns -------------------------------------------------------
    def available_columns
      return @available_columns if @available_columns

      super
      if reaction_query_allowed? &&
         @available_columns.none? { |c| c.name == :reactions_count }
        @available_columns << ReactionsCountColumn.new
      end
      @available_columns
    end

    # ---- filters -------------------------------------------------------
    def initialize_available_filters
      super
      return unless reaction_query_allowed?

      add_available_filter(
        'reactions_count',
        type: :integer, name: l(:label_reactions_count)
      )
      if User.current.logged?
        add_available_filter(
          'reacted_by_id',
          type: :list,
          name: l(:label_reacted_by),
          values: -> { [["<< #{l(:label_me)} >>", 'me']] }
        )
      end
    end

    def sql_for_reactions_count_field(_field, operator, value)
      expr = IssueQueryPatch.count_sql
      case operator
      when '='  then "#{expr} = #{value.first.to_i}"
      when '>=' then "#{expr} >= #{value.first.to_i}"
      when '<=' then "#{expr} <= #{value.first.to_i}"
      when '><' then "#{expr} BETWEEN #{value[0].to_i} AND #{value[1].to_i}"
      when '*'  then "#{expr} > 0"
      when '!*' then "#{expr} = 0"
      else '1=0'
      end
    end

    # Only "me" is offered, so other users' reactions are never exposed.
    def sql_for_reacted_by_id_field(_field, operator, _value)
      return '1=0' unless User.current.logged?

      sub = "SELECT rb.reactable_id FROM #{::Reaction.table_name} rb " \
            "WHERE rb.reactable_type = 'Issue' AND rb.user_id = #{User.current.id.to_i}"
      "#{::Issue.table_name}.id #{operator == '=' ? 'IN' : 'NOT IN'} (#{sub})"
    end

    # ---- preload count for the displayed page --------------------------
    def issues(options = {})
      list = super
      if has_column?(:reactions_count) && list.any?
        counts = ::Reaction.where(reactable_type: 'Issue', reactable_id: list.map(&:id))
                           .group(:reactable_id).count
        list.each { |i| i.instance_variable_set(:@reactions_count_value, counts[i.id] || 0) }
      end
      list
    end

    private

    # Reactions enabled in settings AND the user has the permission
    # in at least one project (or globally).
    def reaction_query_allowed?
      Setting.reactions_enabled? &&
        User.current.allowed_to?(:use_reaction_query, project, global: true)
    end
  end
end
