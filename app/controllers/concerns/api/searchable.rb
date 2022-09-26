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
        "#{self.class.controller_name}.#{attr.to_s}"
      elsif attr.is_a?(String)
        attr
      end
    end

    private

    def apply_searchable(query)
      return query unless params[:search].present?

      or_query = nil

      self.class.search_attributes.each do |attr|
        attribute_query = resolve_search_query(attr)

        if or_query.nil?
          or_query = attribute_query
        else
          or_query = or_query.or(attribute_query)
        end
      end

      query.merge(or_query)
    end
  end
end
