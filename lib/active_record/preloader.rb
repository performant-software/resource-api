class Preloader < ActiveRecord::Associations::Preloader
  # After applying the scope, set @scope to "true"
  def preloaders_for_reflection(reflection, records, scope)
    scope = @scope ? nil : scope
    @scope = true

    super(reflection, records, scope)
  end

  # Overriding to use custom Association class
  def preloader_for(reflection, owners)
    if owners.all? { |o| o.association(reflection.name).loaded? }
      return AlreadyLoaded
    end
    reflection.check_preloadable!

    if reflection.options[:through]
      ThroughAssociation
    else
      Association
    end
  end

  # The default implementation does not associate the records to owners if a scope is applied. Here we'll
  # always associate the records to the owners, assuming the applied scope should persist.
  class Association < ActiveRecord::Associations::Preloader::Association
    def run
      owners.each do |owner|
        associate_records_to_owner(owner, records_by_owner[owner] || [])
      end

      self
    end
  end
end
