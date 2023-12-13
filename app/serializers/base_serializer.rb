class BaseSerializer
  # Includes
  include ObjectSerializer

  attr_reader :current_user, :options

  def initialize(current_user = nil, options = {})
    @current_user = current_user
    @options = options
  end

  def render_index(items)
    return [] if items.nil?

    serialized = []

    # Set all of the base attributes
    [items].flatten.each do |item|
      item_serialized = {}

      self.class.index_attributes&.map do |a|
        extract_value item_serialized, item, a
      end

      serialized << item_serialized
    end

    serialized
  end

  def render_show(item)
    return {} if item.nil?

    serialized = {}

    # Set all of the base attributes
    self.class.show_attributes&.each do |a|
      extract_value serialized, item, a
    end

    serialized
  end

  private

  def extract_value(serialized, item, attribute)
    return nil unless item.present?

    # If the passed attribute is a property on the item, simply extract the value by calling the method
    if attribute.is_a?(Symbol)
      serialized[attribute] = item.send(attribute)

    # If the passed attribute is a hash, we'll check the value type to determine how to handle it
    elsif attribute.is_a?(Hash)
      attribute.keys.each do |key|
        value = attribute[key]

        # If the value is a proc, we'll call the proc to extract the value
        if value.is_a?(Proc)
          serialized[key] = value.call(item, current_user, options)

        # If the value is an array and the attribute name is a has_many relationship, we'll extract an array of values
        elsif value.is_a?(Array) && is_has_many?(item, key)
          related_items = item.send(key)
          related_attributes = attribute[key]

          serialized[key] = []

          related_items.each do |i|
            related_serialized = {}

            related_attributes.each do |a|
              extract_value related_serialized, i, a
            end

            serialized[key] << related_serialized
          end

        # TODO: Comment me
        elsif value.is_a?(Array) && (is_belongs_to?(item, key) || is_has_one?(item, key))
          related_item = item.send(key)
          related_attributes = attribute[key]

          related_serialized = {}

          related_attributes.each do |a|
            extract_value related_serialized, related_item, a
          end

          serialized[key] = related_serialized

        # If the value is a serializer class, grab the related item, initialize the serializer, and extract the value
        # from the index render method.
        elsif value.is_a?(Class) && (is_belongs_to?(item, key) || is_has_one?(item, key))
          related_item = item.send(key)
          serialized[key] = value.new(current_user, options).render_index(related_item)&.first

        # If the value is a serializer class, grab the related item, initialize the serializer, iterate over the related
        # items and extract the value from the index render method.
        elsif value.is_a?(Class) && is_has_many?(item, key)
          related_items = item.send(key)
          serializer = value.new(current_user, options)

          serialized[key] = serializer.render_index(related_items)

        # If the value is a serializer class, grab the current item and extract the value from the render_index method.
        elsif value.is_a?(Class) && value.ancestors.include?(BaseSerializer)
          serializer = value.new(current_user, options)
          serialized[key] = serializer.render_index(item)
        end
      end
    end
  end

  def is_belongs_to?(item, relationship)
    item.class.reflect_on_all_associations(:belongs_to).map(&:name).include?(relationship)
  end

  def is_has_many?(item, relationship)
    item.class.reflect_on_all_associations(:has_many).map(&:name).include?(relationship)
  end

  def is_has_one?(item, relationship)
    item.class.reflect_on_all_associations(:has_one).map(&:name).include?(relationship)
  end

end
