module Api::Filterable
  extend ActiveSupport::Concern

  included do
    # Filter types
    TYPE_BOOLEAN = 'boolean'
    TYPE_DATE = 'date'
    TYPE_RELATIONSHIP = 'relationship'
    TYPE_STRING = 'string'
    TYPE_TEXT = 'text'

    # Filter operators
    OPERATOR_EQUAL = 'equal'
    OPERATOR_NOT_EQUAL = 'not_equal'
    OPERATOR_CONTAIN = 'contain'
    OPERATOR_NOT_CONTAIN = 'not_contain'
    OPERATOR_EMPTY = 'empty'
    OPERATOR_NOT_EMPTY = 'not_empty'
    OPERATOR_LESS_THAN = 'less_than'
    OPERATOR_GREATER_THAN = 'greater_than'

    def apply_filterable(query)
      return query unless params[:filters].present?

      params[:filters].each do |filter|
        association = filter[:association_name]
        type = filter[:type]

        custom_query = process_filter(query, filter)

        if custom_query
          query = custom_query
        elsif association.present?
          query = filter_association(query, filter, association.to_sym)
        elsif type == TYPE_BOOLEAN
          query = filter_boolean(query, filter)
        elsif type == TYPE_DATE
          query = filter_date(query, filter)
        else
          query = filter_default(query, filter)
        end
      end

      query
    end

    protected

    # Not implemented. Provides a hook for implementing controllers to customize how a filter is applied.
    def process_filter(query, filter)
      nil
    end

    private

    def filter_association(query, filter, association)
      if item_class.reflect_on_all_associations(:belongs_to).map(&:name).include?(association) ||
         item_class.reflect_on_all_associations(:has_one).map(&:name).include?(association)
        filter_default(query.joins(association), filter)
      elsif item_class.reflect_on_all_associations(:has_many).map(&:name).include?(association)
        filter_has_many(query, filter)
      end
    end

    def filter_boolean(query, filter)
      query.where(filter[:attribute_name] => filter[:value])
    end

    def filter_date(query, filter)
      attribute = filter[:attribute_name]
      date = filter[:value]

      return query unless date[:startDate].present? && date[:endDate].present?

      start_date = DateTime.parse(date[:startDate])
      end_date = DateTime.parse(date[:endDate])

      query.where(attribute => start_date..end_date)
    end

    def filter_default(query, filter)
      attribute = filter[:attribute_name]
      value = filter[:value]

      case filter[:operator]
      when OPERATOR_EQUAL
        query.where(attribute => value)
      when OPERATOR_NOT_EQUAL
        query.where.not(attribute => value)
      when OPERATOR_CONTAIN
        query.where("#{attribute} ILIKE ?", "%#{value}%")
      when OPERATOR_NOT_CONTAIN
        query.where.not("#{attribute} ILIKE ?", "%#{value}%")
      when OPERATOR_EMPTY
        query.where(attribute => nil)
      when OPERATOR_NOT_EMPTY
        query.where.not(attribute => nil)
      else
        query
      end
    end

    def filter_has_many(query, filter)
      attribute = filter[:attribute_name]
      value = filter[:value]

      association_class = filter[:association_name].to_sym
      association_column = filter[:association_column].to_sym

      association = item_class.reflect_on_association(association_class)
      related_class = association.klass

      subquery = related_class.where(related_class.arel_table[association_column].eq(item_class.arel_table[:id]))
      subquery = subquery.merge(association.scope) if association.scope.present?

      case filter[:operator]
      when OPERATOR_EQUAL
        query.where(subquery.where(attribute => value).arel.exists)
      when OPERATOR_NOT_EQUAL
        query.where(subquery.where.not(attribute => value).arel.exists)
      when OPERATOR_CONTAIN
        query.where(subquery.where("#{attribute} ILIKE ?", "%#{value}%").arel.exists)
      when OPERATOR_NOT_CONTAIN
        query.where(subquery.where.not("#{attribute} ILIKE ?", "%#{value}%").arel.exists)
      when OPERATOR_EMPTY
        query.where.not(subquery.arel.exists)
      when OPERATOR_NOT_EMPTY
        query.where(subquery.arel.exists)
      else
        query
      end
    end
  end

end
