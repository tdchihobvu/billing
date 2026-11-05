class ProductCategory < ApplicationRecord
	belongs_to :parent, :class_name => "ProductCategory", :foreign_key  => "parent_id", optional: true

	def description
		if parent.present?
			"#{parent.name}/#{name}"
		else
			"#{name}"
		end
	end
end
