module ObjectSerializer
  extend ActiveSupport::Concern

  included do

    def self.index_attributes(*attrs, &block)
      @index_attributes ||= []

      if attrs.present?
        if attrs.size == 1 && block.present?
          @index_attributes << { attrs[0] => block }
        else
          @index_attributes += attrs
        end
      end

      @index_attributes
    end

    def self.show_attributes(*attrs, &block)
      @show_attributes ||= []

      if attrs.present?
        if attrs.size == 1 && block.present?
          @show_attributes << { attrs[0] => block }
        else
          @show_attributes += attrs
        end
      end

      @show_attributes
    end

  end
end