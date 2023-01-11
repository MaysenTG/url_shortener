class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  
  before_create :create_short_url

  def create_short_url
    self.shortened_url = generate_short_url
    until Url.where(shortened_url: self.shortened_url).first.nil?
      self.shortened_url = generate_short_url
    end
  end
  
  def generate_short_url
    rand(36**8).to_s(36)
  end
end
