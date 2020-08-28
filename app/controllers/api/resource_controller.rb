class Api::ResourceController < Api::BaseController
  # Includes
  include Api::Queryable
  include Pagy::Backend

  def create
    item = item_class.new(prepare_params)

    if item.save
      item = prepare_item(item)
      render json: { param_name.to_sym => serializer_class.new.render_index(item) }
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
    query = apply_filters(query)
    query = apply_sort(query)

    list, items = pagy(query, items: self.class.per_page, page: params[:page])
    metadata = pagy_metadata(list)

    serializer = serializer_class.new
    serialized = items.map{ |i| serializer.render_index(i) }

    render json: { param_name.pluralize.to_sym  => serialized,
                   list: { page: metadata[:page], pages: metadata[:pages] } }
  end

  def show
    query = base_query
    query = build_query(query)

    item = query.find(params[:id])
    item_name = param_name.to_sym
    item = prepare_item(item)

    render json: { item_name => serializer_class.new.render_show(item) }
  end

  def update
    item = item_class.find(params[:id])

    if item.update(prepare_params)
      item_name = param_name.to_sym
      item = prepare_item(item)

      render json: { item_name => serializer_class.new.render_index(item) }
    else
      render json: { errors: item.errors }, status: 400
    end
  end

  protected

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

      nested_attributes = permitted_parameter.keys.first
      nested_attributes_param = nested_attributes.to_s.sub('_attributes', '').to_sym

      next unless parameters[nested_attributes_param].present?

      attributes = parameters.delete(nested_attributes_param)

      if attributes.is_a?(Array)
        parameters[nested_attributes] = attributes.map do |v|
          rename_params(v, permitted_parameter[nested_attributes])
        end
      else
        parameters[nested_attributes] = attributes
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

  def apply_filters(query)
    query
  end

  def apply_sort(query)
    return query unless params[:sort_by].present?

    sort_by = params[:sort_by].to_sym
    sort_direction = params[:sort_direction] == 'descending' ? :desc : :asc

    query.order(sort_by => sort_direction)
  end

  def param_name
    controller_name.singularize
  end
end