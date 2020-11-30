module Api::Searchable
  extend ActiveSupport::Concern

  included do
    def self.search_attributes(*attrs)
      @attrs ||= []

      # Iterate over the attributes and add them for the list.
      #
      # For symbols, we'll assume that the column is on the primary table and use the controller name to format the SQL
      # as <table-name>.<column_name>.
      #
      # For strings, we'll assume that the column is NOT on the primary table (instead possibly a join table) and
      # allow the controller to format the SQL as appropriate.
      attrs&.each do |attr|
        if attr.is_a?(Symbol)
          @attrs << "#{self.controller_name}.#{attr.to_s}"
        elsif attr.is_a?(String)
          @attrs << attr
        end
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
