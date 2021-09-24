module Api::BatchUpdateable
  # Batch update operators
  OPERATOR_ADD = 'add'
  OPERATOR_REMOVE = 'remove'

  # Batch update types
  TYPE_RELATIONSHIP = 'relationship'

  def batch_delete
    errors = process_delete

    if errors.present?
      render json: { errors: errors }, status: 400
    else
      render json: { status: :ok }
    end
  end

  def batch_update
    errors = process_update

    if errors.present?
      render json: { errors: errors }, status: 400
    else
      render json: { status: :ok }
    end
  end

  protected

  def process_delete
    destroy_all item_class.where(id: params[:ids])
  end

  def process_update
    if params[:type] === TYPE_RELATIONSHIP && params[:multiple].to_s.to_bool
      errors = update_has_many
    else
      errors = update_default
    end

    errors
  end

  private

  def destroy_all(query)
    error = nil

    begin
      query.destroy_all
    rescue => e
      error = e.message
    end

    error
  end

  def insert_all(klass, data, unique_by = nil)
    error = nil

    begin
      klass.insert_all(data, unique_by: unique_by)
    rescue => e
      error = e.message
    end

    error
  end

  def update_all(ids, attributes)
    error = nil

    begin
      item_class
        .where(id: ids)
        .update_all(attributes)
    rescue => e
      error = e.message
    end

    error
  end

  def update_default
    ids = params[:ids]
    attributes = { params[:attribute_name] => params[:value] }

    update_all ids, attributes
  end

  def update_has_many
    operator = params[:operator]
    association_column = params[:association_column].to_sym

    association = item_class.reflect_on_association(params[:association_name].to_sym)
    klass = association.klass
    id_key = association.foreign_key

    if operator == OPERATOR_ADD
      data = []

      params[:ids].each do |id|
        params[:value].each do |value|
          data << { id_key => id, association_column => value }
        end
      end

      error = insert_all(klass, data, [association_column, id_key])
    elsif operator == OPERATOR_REMOVE
      criteria = {
        id_key => params[:ids],
        association_column => params[:value]
      }

      error = destroy_all(klass.where(criteria))
    end

    error
  end

end
