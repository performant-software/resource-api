module Api::Searchable
  extend ActiveSupport::Concern

  class_methods do
    def search_attributes(*attrs)
      @attrs ||= []
      @attrs += attrs
      @attrs
    end

    def search_methods(*methods)
      @search_methods ||= []
      @search_methods += methods unless methods.nil?
      @search_methods
    end
  end

  included do

    def apply_search(query)
      search_query = nil

      [:apply_searchable, *self.class.search_methods].each do |method|
        search_query = self.send(method, search_query.nil? ? item_class.all : search_query)
      end

      query.merge(search_query)
    end

    def resolve_search_query(attr)
      attribute = resolve_search_attribute(attr)
      item_class.where("#{attribute} ILIKE ?", "%#{params[:search]}%")
    end

    def resolve_search_attribute(attr)
      if attr.is_a?(Symbol)
        "#{item_class.table_name}.#{attr.to_s}"
      elsif attr.is_a?(String)
        attr
      end
    end

    private

    def apply_searchable(query)
      # No need to apply a search if no parameter is applied
      return query unless params[:search].present?

      # No need to apply a search if no attributes are provided
      return query if self.class.search_attributes.empty?

      # Split search into tokens on whitespace
      tokens = params[:search].to_s.split

      # No need to apply a search if no tokens to search on
      return query if tokens.empty?

      # Resolve searchable attributes to columns
      attributes = self.class.search_attributes.map { |attr| resolve_search_attribute(attr) }

      # Build ILIKE query for each token
      search_query = item_class.all

      tokens.each do |token|
        condition = attributes.map { |attribute| "#{attribute} ILIKE ?" }.join(' OR ')

        # sanitize to escape any LIKE wildcards ("%", "_")
        sanitized = ActiveRecord::Base.sanitize_sql_like(token)
        values = attributes.map { "%#{sanitized}%" }

        search_query = search_query.where("(#{condition})", *values)
      end

      if query == item_class.all
        query.merge(search_query)
      else
        query.or(search_query)
      end
    end
  end
end
