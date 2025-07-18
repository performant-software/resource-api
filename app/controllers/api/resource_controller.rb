class Api::ResourceController < ActionController::API
  # Includes
  include Api::Queryable
  include Api::Searchable
  include Api::Sortable
  include Pagy::Backend
  include Pundit::Authorization

  # Authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :unauthorized

  def initialize
    @authorize = true
  end

  def create
    item = item_class.new(prepare_params)
    authorize item, policy_class: policy_class if authorization_valid?

    if item.save
      after_create(item)

      item = prepare_item(item)
      preloads(item)

      render json: build_show_response(item), status: :ok
    else
      render json: { errors: item.errors }, status: :bad_request
    end
  end

  def destroy
    item = find_record(item_class)
    authorize item, policy_class: policy_class if authorization_valid?

    if item.destroy
      after_destroy
      render json: { status: :ok }
    else
      render json: { errors: item.errors }, status: :bad_request
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

    render json: build_index_response(items, metadata), status: :ok
  end

  def show
    query = base_query
    query = build_query(query)

    item = find_record(query)
    authorize item, policy_class: policy_class if authorization_valid?

    item = prepare_item(item)
    preloads(item)

    render json: build_show_response(item), status: :ok
  end

  def update
    item = find_record(item_class)
    authorize item, policy_class: policy_class if authorization_valid?

    if item.update(prepare_params(item))
      after_update(item)

      item = prepare_item(item)
      preloads(item)

      render json: build_show_response(item), status: :ok
    else
      render json: { errors: item.errors }, status: :bad_request
    end
  end

  protected

  def after_create(item)
    # Implemented in sub-classes
  end

  def after_destroy
    # Implemented in sub-classes
  end

  def after_update(item)
    # Implemented in sub-classes
  end

  def apply_filters(query)
    query
  end

  def authorization_valid?
    has_policy? && @authorize
  end

  def base_query
    if authorization_valid?
      policy_scope item_class, policy_scope_class: policy_scope_class
    else
      item_class.all
    end
  end

  def build_index_response(items, metadata)
    options = load_records(items)
    serializer = serializer_class.new(current_user, options)
    serialized = serializer.render_index(items)

    {
      param_name.pluralize.to_sym  => serialized,
      list: {
        count: metadata[:count],
        page: metadata[:page],
        pages: metadata[:pages]
      }
    }
  end

  def build_show_response(item)
    options = load_records(item)
    serializer = serializer_class.new(current_user, options)

    { param_name.to_sym => serializer.render_show(item) }
  end

  def bypass_authorization
    @authorize = false
  end

  def find_record(query)
    query.find(params[:id])
  end

  def load_records(item)
    {}
  end

  def permitted_params(item = nil)
    if authorization_valid?
      policy = policy_class.new(current_user, item)
      action_params_method = "permitted_attributes_for_#{action_name}".to_sym

      if policy.respond_to?(action_params_method)
        method_name = action_params_method
      elsif policy.respond_to?(:permitted_attributes)
        method_name = :permitted_attributes
      end

      return policy.send(method_name) unless method_name.nil?
    end

    item_class.permitted_params
  end

  def prepare_item(item)
    item
  end

  def prepare_params(item = nil)
    # Replace nested attributes parameter names with the "_attributes" version
    params[param_name] = rename_params(params[param_name], permitted_params(item))

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

  def policy_class
    begin
      Module.const_get("#{item_class.to_s}Policy")
    rescue NameError
      nil
    end
  end

  def policy_scope_class
    begin
      Module.const_get("#{policy_class.to_s}::Scope")
    rescue NameError
      nil
    end
  end

  private

  def has_policy?
    begin
      policy_class&.is_a?(Class)
    rescue NameError
      false
    end
  end

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

  def unauthorized(error)
    policy_name = error.policy.class.to_s.underscore
    message = I18n.t("authorization.#{policy_name}.#{error.query}")

    render json: { errors: [{ base: message }] }, status: :unauthorized
  end
end
