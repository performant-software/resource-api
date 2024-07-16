module Api::Uploadable
  extend ActiveSupport::Concern

  included do

    def upload
      render json: { errors: ['Uploadable contents required'] }, status: 400 and return unless params[controller_name.to_sym]

      items = []
      errors = []

      begin
        item_class.transaction do
          items = item_class.create(upload_params)
          errors = items.map(&:errors).delete_if(&:empty?)
        end
      rescue ActiveRecord::RecordInvalid => exception
        errors = [exception]
      end

      if errors.empty?
        serializer = serializer_class.new
        render json: { controller_name.to_sym => items.map{ |i| serializer.render_index(i) } }, status: :ok
      else
        render json: { errors: errors }, status: 422
      end
    end

    def upload_params
      params[controller_name.to_sym].keys.map do |key|
        # Rename nested attributes
        params[controller_name.to_sym][key] = rename_params(params[controller_name.to_sym][key], permitted_params)

        # Set any blank strings to nil
        params[controller_name.to_sym][key]
          .permit(permitted_params)
          .to_h
          .inject({}) { |h, (k, v)| h[k] = (v.is_a?(String) && v.blank?) ? nil : v; h }
      end
    end

  end

end
