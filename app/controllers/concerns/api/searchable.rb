module Api::Searchable
  extend ActiveSupport::Concern

  included do
    def self.search_attributes(*attrs)
      @attrs ||= []
      attrs.each do |attr|
        @attrs << "#{self.controller_name}.#{attr.to_s}" if attrs.present?
      end
      @attrs
    end

    def apply_search(query)
      return query unless params[:search].present?
      query_string = "#{self.class.search_attributes.map{|attr| attr + " ILIKE ?"}.join(" OR ")}"
      query_args = (self.class.search_attributes.count).times.map {"%#{params[:search]}%"}

      query.where(query_string, *query_args)
    end

  end

end
