class LinkClick < ApplicationRecord
  belongs_to :url

  validates :clicked_at, presence: true
end
