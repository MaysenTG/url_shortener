require 'uri';

class Url < ApplicationRecord  
  validates :original_url, presence: true, format: { with: /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?/ix, multiline: true, message: "URL must be valid" }
  
  # Add validation for an empty URL input
  validates :original_url, presence: true, length: { minimum: 1, message: "URL must not be empty" }
end
