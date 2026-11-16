class UserTarget < ApplicationRecord
  belongs_to :user
  # The column is named currency, so the association cannot share that name.
  belongs_to :target_currency, class_name: "Currency", foreign_key: "currency"
end
