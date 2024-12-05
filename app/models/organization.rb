class Organization < ApplicationRecord
    belongs_to :owner, class_name: 'User'

    validates :name, presence: true
    validates :industry, presence: true
end
