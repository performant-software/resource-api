# This class overrides the Branch class from active_record, specifially to ensure that any scope is only applied to the
# parent relationship. For example, if we have a nested preload { author: [books: :titles] }, we would only want a scope
# to be applied to the parent "author" query.
#
# If the future, we should probably find a better way to handle this so that we're not constantly patching
# active_record code with each Rails release.
#
class Preloader < ActiveRecord::Associations::Preloader
  def initialize(records:, associations:, scope: nil, available_records: [], associate_by_default: true)
    @records = records
    @associations = associations
    @scope = scope
    @available_records = available_records || []
    @associate_by_default = associate_by_default

    @tree = Branch.new(
      parent: nil,
      association: nil,
      children: @associations,
      associate_by_default: @associate_by_default,
      scope: @scope
    )
    @tree.preloaded_records = @records
  end

  def branches
    @tree.children
  end

  class Branch < ActiveRecord::Associations::Preloader::Branch
    def build_children(children)
      Array.wrap(children).flat_map { |a|
        Array(a).flat_map { |p, c|
          Branch.new(
            parent: self,
            association: p,
            children: c,
            associate_by_default: associate_by_default,
            scope: parent.nil? ? scope : nil
          )
        }
      }
    end

  end
end
