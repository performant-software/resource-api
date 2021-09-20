module Api::Queryable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 10

  included do
    def self.joins(*joins)
      @joins ||= []
      @joins << joins if joins.present?
      @joins
    end

    def self.left_joins(*left_joins)
      @left_joins ||= []
      @left_joins << left_joins if left_joins.present?
      @left_joins
    end

    def self.per_page(per_page = nil)
      @per_page = per_page if per_page.present?
      @per_page || DEFAULT_PER_PAGE
    end

    def self.preloads(*preloads)
      @preloads ||= []
      @preloads << preloads if preloads.present?
      @preloads
    end

    def build_query(query)
      q = apply_preloads(query)
      q = apply_joins(q)
      q = apply_left_joins(q)

      q
    end

    def preloads(query)
      return unless self.class.preloads.present?

      self.class.preloads.each do |preloads|
        next if skip_relationships?(preloads)
        preloads.each do |preload|
          next unless conditional?(preload)

          scope = apply_scope?(preload) ? preload[:scope] : nil
          Preloader.new.preload(query, process_relationship(preload), scope)
        end
      end

      query
    end

    private

    def conditional?(relationship)
      relationship.is_a?(Hash) && relationship.has_key?(:scope)
    end

    def apply_joins(query)
      return query unless self.class.joins.present?

      self.class.joins.each do |joins|
        next if skip_relationships?(joins)
        joins.each do |join|
          query = query.joins process_relationship(join)
        end
      end

      query
    end

    def apply_left_joins(query)
      return query unless self.class.left_joins.present?

      self.class.left_joins.each do |left_joins|
        next if skip_relationships?(left_joins)
        left_joins.each do |left_join|
          query = query.left_joins process_relationship(left_join)
        end
      end

      query
    end

    def apply_preloads(query)
      return query unless self.class.preloads.present?

      self.class.preloads.each do |preloads|
        next if skip_relationships?(preloads)
        preloads.each do |preload|
          next if conditional?(preload)
          query = query.preload process_relationship(preload)
        end
      end

      query
    end

    def apply_scope?(relationship)
      return false unless relationship.is_a?(Hash) && relationship[:scope].present?
      return true unless relationship[:if].present?

      condition = relationship[:if]

      if condition.is_a?(Proc)
        apply_scope = condition.call
      elsif condition.is_a?(Symbol)
        apply_scope = self.send(condition)
      end

      apply_scope
    end

    def process_relationship(relationship)
      return relationship unless relationship.is_a?(Hash)
      relationship.except(:only, :except, :scope, :if)
    end

    def skip_relationships?(relationships)
      return false unless relationships.is_a?(Array)

      only_actions = []
      except_actions = []

      relationships.each do |relationship|
        next unless relationship.is_a?(Hash)

        if relationship.keys.include?(:only)
          only_actions.push(*relationship[:only])
        elsif relationship.keys.include?(:except)
          except_actions.push(*relationship[:except])
        end
      end

      return false if only_actions.empty? && except_actions.empty?

      only_actions.exclude?(params[:action].to_sym) || except_actions.include?(params[:action].to_sym)
    end
  end
end
