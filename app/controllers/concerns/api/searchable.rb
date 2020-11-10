module Api::Searchable
  extend ActiveSupport::Concern

  included do
    def self.search_attributes(*attrs)
      @attrs ||= []
      attrs.each do|attr|
        @attrs << "#{self.controller_name}.#{attr.to_s}" if attrs.present?
      end
      @attrs
    end

    def apply_search(query)
      return query unless params[:search].present?
      byebug
      query.where("#{self.class.search_attributes.join(" OR ")} ILIKE ?", "%#{params[:search]}%")
    end

  end

end
