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

    private

    def apply_joins(query)
      return query unless self.class.joins.present?

      self.class.joins.each do |joins|
        next if skip_relationships?(joins)
        joins.each do |join|
          next if skip_relationship?(join)
          query = query.joins(join)
        end
      end

      query
    end

    def apply_left_joins(query)
      return query unless self.class.left_joins.present?

      self.class.left_joins.each do |left_joins|
        next if skip_relationships?(left_joins)
        left_joins.each do |left_join|
          next if skip_relationship?(left_join)
          query = query.left_joins(left_join)
        end
      end

      query
    end

    def apply_preloads(query)
      return query unless self.class.preloads.present?

      self.class.preloads.each do |preloads|
        next if skip_relationships?(preloads)
        preloads.each do |preload|
          next if skip_relationship?(preload)
          query = query.preload(preload)
        end
      end

      query
    end

    def skip_relationship?(relationship)
      r = relationship.is_a?(Hash) ? relationship.keys.first : relationship
      return true if %i(only except).include?(r)

      params[:action] == :index.to_s && item_class.reflect_on_all_associations(:has_many).map(&:name).include?(r)
    end

    def skip_relationships?(relationships)
      return false unless relationships.is_a?(Array)

      actions = relationships.select{ |r| r.is_a?(Hash) }.first
      return false unless actions.present?

      if actions[:only].present?
        actions = actions[:only].is_a?(Array) ? actions[:only] : [actions[:only]]
        actions.include?(params[:action])
      elsif routes[:except].present?
        actions = actions[:except].is_a?(Array) ? actions[:except] : [actions[:except]]
        !actions.include?(params[:action])
      else
        false
      end
    end
  end
end