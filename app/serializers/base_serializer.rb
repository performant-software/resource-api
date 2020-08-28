class BaseSerializer
  # Includes
  include ObjectSerializer

  def initialize(related = false)
    @related = related
  end

  def related?
    @related
  end

  def render_index(item)
    return {} if item.nil?

    serialized = {}

    # Set all of the base attributes
    self.class.index_attributes&.map do |a|
      serialized[a] = item.send(a)
    end

    return serialized if related?

    # Set all of the belongs_to attributes
    self.class.belongs_to&.each do |b|
      b.keys.each do |a|
        serializer = b[a]
        related_item = item.send(a)
        serialized[a] = serializer.new(true).render_index(related_item)
      end
    end

    # Set all of the has_one attributes
    self.class.has_one&.each do |r|
      relationship = r.keys.first
      related_item = item.send(relationship)

      next if related_item.nil?

      serialized[relationship] = render_related_item(related_item, r[relationship])
    end

    serialized
  end

  def render_show(item)
    return {} if item.nil?

    serialized = {}

    # Set all of the base attributes
    self.class.show_attributes&.each do |a|
      serialized[a] = item.send(a)
    end

    # Set all of the belongs_to attributes
    self.class.belongs_to&.each do |b|
      b.keys.each do |a|
        serializer = b[a]
        related_item = item.send(a)
        serialized[a] = serializer.new(true).render_index(related_item)
      end
    end

    # Set all of the has_many attributes
    self.class.has_many&.each do |r|
      relationship = r.keys.first

      serialized[relationship] = item.send(relationship)&.map do |related_item|
        render_related_item(related_item, r[relationship])
      end
    end

    # Set all of the has_one attributes
    self.class.has_one&.each do |r|
      relationship = r.keys.first
      related_item = item.send(relationship)

      next if related_item.nil?

      serialized[relationship] = render_related_item(related_item, r[relationship])
    end

    serialized
  end

  private

  def render_related_item(related_item, attributes)
    attributes.inject({}) do |serialized, attribute|
      if attribute.is_a?(Hash)
        attribute.keys.each do |key|
          obj = related_item.send(key)

          serializer_class = attribute[key]
          serialized[key] = serializer_class.new(true).render_index(obj)
        end
      else
        serialized[attribute] = related_item.send(attribute)
      end

      serialized
    end
  end
end