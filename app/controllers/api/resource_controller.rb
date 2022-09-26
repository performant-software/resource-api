class Api::ResourceController < ActionController::API
  # Includes
  include Api::Queryable
  include Api::Searchable
  include Api::Sortable
  include Pagy::Backend

  def create
    item = item_class.new(prepare_params)

    if item.save
      item = prepare_item(item)

      preloads(item)

      serializer = serializer_class.new(current_user)
      render json: { param_name.to_sym => serializer.render_index(item) }
    else
      render json: { errors: item.errors }, status: 400
    end
  end

  def destroy
    item = item_class.find(params[:id])

    if item.destroy
      render json: { status: :ok }
    else
      render json: { errors: item.errors }, status: 400
    end
  end

  def index
    query = base_query
    query = build_query(query)
    query = apply_search(query)
    query = apply_filters(query)
    query = apply_sort(query)

    list, items = pagy(query, items: per_page, page: params[:page])
    metadata = pagy_metadata(list)

    preloads(items)

    serializer = serializer_class.new(current_user)
    serialized = items.map{ |i| serializer.render_index(i) }

    render json: { param_name.pluralize.to_sym  => serialized,
                   list: {
                     count: metadata[:count],
                     page: metadata[:page],
                     pages: metadata[:pages]
                   }
                 }
  end

  def show
    query = base_query
    query = build_query(query)

    item = query.find(params[:id])
    item_name = param_name.to_sym

    item = prepare_item(item)
    preloads(item)

    serializer = serializer_class.new(current_user)
    render json: { item_name => serializer.render_show(item) }
  end

  def update
    item = item_class.find(params[:id])

    if item.update(prepare_params)

      item = prepare_item(item)
      preloads(item)

      item_name = param_name.to_sym
      serializer = serializer_class.new(current_user)

      render json: { item_name => serializer.render_index(item) }
    else
      render json: { errors: item.errors }, status: 400
    end
  end

  protected

  def apply_filters(query)
    query
  end

  def base_query
    item_class.all
  end

  def permitted_params
    item_class.permitted_params
  end

  def prepare_item(item)
    item
  end

  def prepare_params
    # Replace nested attributes parameter names with the "_attributes" version
    params[param_name] = rename_params(params[param_name], permitted_params)

    params
      .require(param_name.to_sym)
      .permit(permitted_params)
      .to_h
      .inject({}) { |h, (k, v)| h[k] = (v.is_a?(String) && v.blank?) ? nil : v; h }
  end

  def rename_params(parameters, permitted_parameters)
    permitted_parameters.each do |permitted_parameter|
      next unless permitted_parameter.is_a?(Hash)

      permitted_parameter.keys.each do |nested_attributes|
        nested_attributes_param = nested_attributes.to_s.sub('_attributes', '').to_sym

        next unless parameters[nested_attributes_param].present?

        attributes = parameters.delete(nested_attributes_param)

        if attributes.is_a?(Array)
          parameters[nested_attributes] = attributes.map do |attrs|
            parameters[nested_attributes] = rename_params(attrs, permitted_parameter[nested_attributes])
          end
        elsif attributes.is_a?(ActionController::Parameters) && attributes.keys.all?(&:is_integer?)
          parameters[nested_attributes] = attributes.keys.map do |key|
            parameters[nested_attributes] = rename_params(attributes[key], permitted_parameter[nested_attributes])
          end
        else
          parameters[nested_attributes] = attributes
        end
      end
    end

    parameters
  end

  def item_class
    controller_name.singularize.classify.constantize
  end

  def serializer_class
    "#{controller_name}_serializer".classify.constantize
  end

  private

  def param_name
    controller_name.singularize
  end

  def per_page
    # Default count to the provided parameter
    count = params[:per_page].to_i if params.has_key?(:per_page) && params[:per_page].respond_to?(:to_i)

    # Use the per_page defined in the controller if no parameter is provided
    count = self.class.per_page if count.nil?

    # If the count is less than or equal to zero, return all records.
    # This will produce an extra query in order to obtain the count
    # of the number of records.
    if count <= 0
      all_count = item_class.all.count
      # Prevent per_page being set to 0 if there are 0 records
      if all_count == 0
        count = self.class.per_page
      else
        count = all_count
      end
    end

    count
  end
end
