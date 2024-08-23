module Api::Sortable
  extend ActiveSupport::Concern

  class_methods do
    def sort_methods(*methods)
      @sort_methods ||= []
      @sort_methods += methods unless methods.nil?
      @sort_methods
    end
  end

  included do
    def apply_sort(query)
      [*self.class.sort_methods, :apply_default_sort].each do |method|
        query = self.send(method, query)
      end

      # Always order records by ID last to avoid non-deterministic ordering
      query = query.order(:id)

      query
    end

    def apply_default_sort(query)
      return query if params[:sort_by].blank? || query.order_values.size > 0

      sort_bys = params[:sort_by].is_a?(Array) ? params[:sort_by] : [params[:sort_by]]
      sort_direction = params[:sort_direction] == 'descending' ? :desc : :asc

      sort_bys.each do |sort_by|
        query = query.order(sort_by.to_sym => sort_direction)
      end

      query
    end
  end
end
