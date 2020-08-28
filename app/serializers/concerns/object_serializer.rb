module ObjectSerializer
  extend ActiveSupport::Concern

  included do
    def self.index_attributes(*attrs)
      @index_attributes ||= []
      @index_attributes += attrs if attrs.present?
      @index_attributes
    end

    def self.show_attributes(*attrs)
      @show_attributes ||= []
      @show_attributes = attrs if attrs.present?
      @show_attributes
    end

    def self.belongs_to(*attrs)
      @belongs_to ||= []
      @belongs_to += attrs if attrs.present?
      @belongs_to
    end

    def self.has_many(*attrs)
      @has_many ||= []
      @has_many += attrs if attrs.present?
      @has_many
    end

    def self.has_one(*attrs)
      @has_one ||= []
      @has_one += attrs if attrs.present?
      @has_one
    end

  end
end